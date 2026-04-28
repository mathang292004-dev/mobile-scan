import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:emergex/data/model/api_response.dart';
import 'package:emergex/domain/api/api_endpoint.dart';
import 'package:emergex/helpers/preference_helper.dart';
import 'package:emergex/helpers/widgets/feedback/session_expired_screen.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:emergex/base/cubit/emergex_app_cubit.dart';
import 'package:emergex/helpers/auth_guard.dart';
import 'package:get_it/get_it.dart';

import 'interceptors/logger.dart';

class FileUploadData {
  final File file;
  final String fieldName;
  final String? fileName;
  final String? contentType;

  FileUploadData({
    required this.file,
    required this.fieldName,
    this.fileName,
    this.contentType,
  });
}

typedef UploadProgressCallback = void Function(int sent, int total);

abstract class ApiClient {
  Future<ApiResponse<T>> request<T>(
    String endpoint, {
    required HttpMethod method,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, String>? headers,
    dynamic Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool requiresProjectId = false,
  });

  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint, {
    required String fieldName,
    required File? file,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool requiresProjectId = false,
    UploadProgressCallback? onUploadProgress,
    CancelToken? cancelToken,
  });

  Future<ApiResponse<T>> uploadMultipleFiles<T>(
    String endpoint, {
    required String fieldName,
    required List<File> files,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool requiresProjectId = false,
    UploadProgressCallback? onUploadProgress,
    CancelToken? cancelToken,
  });
}

class ApiClientImpl implements ApiClient {
  final Dio _dio;
  final PreferenceHelper _preferenceHelper;

  // Token refresh queue mechanism:
  // When a 401 is received, the first caller starts the refresh.
  // Subsequent 401s during the refresh wait on the same Completer.
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  ApiClientImpl(this._dio, this._preferenceHelper) {
    _setupDio();
  }

  /// Lazy-load the EmergexAppCubit to avoid circular dependency
  EmergexAppCubit? _getAppCubit() {
    try {
      return GetIt.instance.isRegistered<EmergexAppCubit>()
          ? GetIt.instance<EmergexAppCubit>()
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Separate Dio instance for refresh token calls.
  /// Has NO interceptors to avoid infinite loops when refresh endpoint
  /// itself returns an error.
  Dio _createRefreshDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  /// Returns true if [path] is an auth endpoint that should NOT trigger
  /// token refresh (to avoid infinite loops).
  bool _isAuthEndpoint(String path) {
    return path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.refreshToken);
  }

  /// Endpoints that should skip the pre-request permission check to avoid
  /// recursion (getPermissions calling itself) or unnecessary calls.
  bool _skipPermissionCheck(String path) {
    return path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.refreshToken) ||
        path.contains(ApiEndpoints.me) ||
        path.contains(ApiEndpoints.getPermissions) ||
        path.contains(ApiEndpoints.resetPassword);
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 60),
      validateStatus: (status) => true,
    );

    try {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.connectionTimeout = null;
        client.idleTimeout = const Duration(days: 1);
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    } catch (e) {
      debugPrint(e.toString());
    }

    _dio.interceptors.addAll([
      LoggerInterceptor(
        level: LogLevel.body,
        maxBodyLength: 30000,
        maskHeaders: {'authorization', 'cookie'},
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['requiresAuth'] == true) {
            // Cancel any authenticated request while logout is in progress.
            // This prevents stale requests (fired before navigation cleared
            // the screen) from reaching the server and triggering a 401
            // which would show the Session Expired dialog.
            if (AuthGuard.isLoggingOut) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  message: 'Request cancelled: logout in progress',
                ),
              );
              return;
            }

            // Always read the LATEST token from storage
            // This ensures retried requests after refresh use the new token
            try {
              final userToken = await _preferenceHelper.getUserToken();
              if (userToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $userToken';
              }
            } catch (_) {}

            // Skip permission check for auth endpoints and retry-after-refresh requests
            final path = options.path;
            final isRetry = options.extra['_isRetryAfterRefresh'] == true;
            if (!_skipPermissionCheck(path) && !isRetry) {
              // Skip if user is logging out — prevents stale permission calls
              // (e.g. triggered by unregister-fcm-token during logout flow)
              final canProceed = await AuthGuard.canProceed();
              if (canProceed) {
                final appCubit = _getAppCubit();
                if (appCubit != null) {
                  await appCubit.getPermissions();
                }
              }
            }
          }

          // Add x-project-id header if endpoint requires it
          if (options.extra['requiresProjectId'] == true) {
            final appCubit = _getAppCubit();
            final selectedProjectId = appCubit?.state.selectedProjectId;
            if (selectedProjectId != null && selectedProjectId.isNotEmpty) {
              options.headers['x-project-id'] = selectedProjectId;
            } else {
              final projects = appCubit?.state.userPermissions?.projects;
              final firstProject = projects?.firstOrNull;
              if (firstProject != null) {
                final firstProjectId = firstProject.projectId;
                if (firstProjectId.isNotEmpty) {
                  options.headers['x-project-id'] = firstProjectId;
                }
              }
            }
          }

          handler.next(options);
        },

        // 401 handling lives here because validateStatus: true means
        // HTTP errors arrive as Response objects, not DioExceptions.
        onResponse: (response, handler) async {
          if (response.statusCode == 401 &&
              response.requestOptions.extra['requiresAuth'] == true &&
              !_isAuthEndpoint(response.requestOptions.path) &&
              response.requestOptions.extra['_isRetryAfterRefresh'] != true) {
            // Attempt token refresh + retry
            final retryResponse = await _handleUnauthorizedResponse(response);
            if (retryResponse != null) {
              handler.resolve(retryResponse);
            } else {
              // Refresh failed — pass the original 401 response through
              handler.next(response);
            }
          } else {
            handler.next(response);
          }
        },

        // Only fires for network-level errors (timeouts, DNS, etc.)
        onError: (error, handler) async {
          handler.next(error);
        },
      ),
    ]);
  }

  /// Handles 401 responses with token refresh + request queue.
  ///
  /// Flow:
  /// 1. If a refresh is already in progress → wait for it, then retry
  /// 2. Otherwise → start a refresh, retry all queued requests on success
  /// 3. On refresh failure → expire session, return null (no retry)
  Future<Response?> _handleUnauthorizedResponse(Response response) async {
    // If another call is already refreshing, wait for it
    if (_isRefreshing && _refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        // Retry this request with the new token
        response.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        response.requestOptions.extra['_isRetryAfterRefresh'] = true;
        try {
          return await _dio.fetch(response.requestOptions);
        } catch (_) {
          return null;
        }
      }
      // Refresh failed — session will be expired by the refreshing caller
      return null;
    }

    // This caller is the first to hit 401 — start the refresh
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final storedRefreshToken = await _preferenceHelper.getRefreshToken();
      if (storedRefreshToken.isEmpty) {
        _completeRefresh(null);
        // If the user deliberately logged out, the refresh token will be
        // empty because clearAll() was called. Don't show Session Expired
        // dialog — this is an expected, clean state.
        if (!AuthGuard.isLoggingOut) {
          _expireSession();
        }
        return null;
      }

      // Use a separate Dio with no interceptors to avoid loops
      final refreshDio = _createRefreshDio();
      final refreshResponse = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': storedRefreshToken},
      );

      if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
        final responseData = refreshResponse.data['data'] as Map<String, dynamic>?;
        // API returns { data: { accessToken, refreshToken } }
        final newToken =
            responseData?['accessToken']?.toString() ??
            responseData?['token']?.toString(); // fallback for old shape

        if (newToken == null) {
          _completeRefresh(null);
          _expireSession();
          return null;
        }

        // Some APIs only return a new accessToken and reuse the existing refreshToken.
        // Fall back to the stored refresh token if the response doesn't include one.
        final newRefreshToken =
            responseData?['refreshToken']?.toString() ?? storedRefreshToken;

        await _preferenceHelper.setUserToken(newToken);
        await _preferenceHelper.setRefreshToken(newRefreshToken);

        // Update Dio default headers so ALL subsequent requests use the new token
        _dio.options.headers['Authorization'] = 'Bearer $newToken';

        // Notify all waiting callers that new token is ready
        _completeRefresh(newToken);

        // Retry the original request with new token
        // Mark as retry to skip permission re-check
        response.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        response.requestOptions.extra['_isRetryAfterRefresh'] = true;
        return await _dio.fetch(response.requestOptions);
      } else {
        // Refresh endpoint returned non-200 (expired refresh token, etc.)
        _completeRefresh(null);
        _expireSession();
        return null;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      _completeRefresh(null);
      _expireSession();
      return null;
    }
  }

  /// Completes the refresh Completer so all waiting callers proceed.
  void _completeRefresh(String? token) {
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete(token);
    }
    _isRefreshing = false;
    _refreshCompleter = null;
  }

  /// Clears all tokens/preferences, shows session expired dialog,
  /// and navigates to login screen with stack cleared.
  void _expireSession() {
    _preferenceHelper.clearAll();
    sessionProvider.expireSession();
  }

  @override
  Future<ApiResponse<T>> request<T>(
    String endpoint, {
    required HttpMethod method,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, String>? headers,
    dynamic Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool requiresProjectId = false,
  }) async {
    try {
      final options = Options(
        method: _getHttpMethod(method),
        headers: headers,
        extra: {
          'requiresAuth': requiresAuth,
          'requiresProjectId': requiresProjectId,
        },
        validateStatus: (status) => true,
        receiveTimeout: const Duration(minutes: 10),
      );

      final Response response;

      switch (method) {
        case HttpMethod.get:
          response = await _dio.get(
            endpoint,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.post:
          response = await _dio.post(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.put:
          response = await _dio.put(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.patch:
          response = await _dio.patch(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
        case HttpMethod.delete:
          response = await _dio.delete(
            endpoint,
            data: data,
            queryParameters: queryParameters,
            options: options,
          );
          break;
      }

      // 401 is now handled centrally by the onResponse interceptor.
      // No duplicate handling needed here.

      return await _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse<T>.error('Unexpected error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> _parseResponse<T>(
    Response response,
    dynamic Function(dynamic)? fromJson,
  ) async {
    try {
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        T? parsedData;
        if (fromJson != null && response.data != null) {
          try {
            final result = await fromJson(response.data);
            parsedData = result as T?;
          } catch (e) {
            // fromJson throws user-facing API error messages (e.g. validation
            // errors like "Phone number is invalid"). Strip the "Exception: "
            // prefix Dart adds to plain Exception objects so the user sees a
            // clean message instead of "Failed to parse response: Exception: …"
            final raw = e.toString();
            final msg = raw.startsWith('Exception: ')
                ? raw.substring('Exception: '.length)
                : raw;
            return ApiResponse<T>.error(msg);
          }
        } else {
          parsedData = response.data as T?;
        }

        final successMsg = _extractMessage(
          response.data,
          fallback: response.statusMessage ?? 'Success',
        );

        return ApiResponse<T>.success(parsedData, message: successMsg);
      } else {
        // The API may return `message` as a List<String> for validation errors
        // (e.g. invalid phone number), or `response.data` may not be a Map at
        // all. _extractMessage handles every shape safely.
        final message = _extractMessage(
          response.data,
          fallback: response.statusMessage ?? 'Request failed',
        );
        return ApiResponse<T>.error(
          message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<T>.error('Failed to parse response: ${e.toString()}');
    }
  }

  @override
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint, {
    required String fieldName,
    required File? file,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool requiresProjectId = false,
    UploadProgressCallback? onUploadProgress,
    CancelToken? cancelToken,
  }) async {
    return uploadMultipleFiles<T>(
      endpoint,
      fieldName: fieldName,
      files: file != null ? [file] : [],
      additionalData: additionalData,
      headers: headers,
      fromJson: fromJson,
      requiresAuth: requiresAuth,
      requiresProjectId: requiresProjectId,
      onUploadProgress: onUploadProgress,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ApiResponse<T>> uploadMultipleFiles<T>(
    String endpoint, {
    required List<File>? files,
    required String fieldName,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
    bool requiresAuth = true,
    bool requiresProjectId = false,
    UploadProgressCallback? onUploadProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData();

      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          if (await file.exists()) {
            final fileName = file.path.split('/').last;
            final encodedFileName = Uri.encodeComponent(fileName);
            final mimeType =
                lookupMimeType(file.path) ?? 'application/octet-stream';

            formData.files.add(
              MapEntry(
                fieldName,
                await MultipartFile.fromFile(
                  file.path,
                  filename: encodedFileName,
                  contentType: MediaType.parse(mimeType),
                ),
              ),
            );
          }
        }
      }

      if (additionalData != null) {
        additionalData.forEach((key, value) {
          if (value != null && value is List) {
            for (var item in value) {
              formData.fields.add(MapEntry('$key[]', item.toString()));
            }
          } else if (value != null) {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });
      }

      final uploadHeaders = <String, dynamic>{'accept': '*/*', ...?headers};
      uploadHeaders.remove('Content-Type');

      final options = Options(
        method: 'POST',
        headers: uploadHeaders,
        extra: {
          'requiresAuth': requiresAuth,
          'requiresProjectId': requiresProjectId,
        },
        validateStatus: (status) => true,
      );

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: options,
        onSendProgress: onUploadProgress,
        cancelToken: cancelToken,
      );

      return _parseResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse<T>.error('Upload failed: ${e.toString()}');
    }
  }

  String _getHttpMethod(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }

  ApiResponse<T> _handleDioError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return ApiResponse<T>.error('Upload cancelled');
      case DioExceptionType.connectionError:
        return ApiResponse<T>.networkError();
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        return ApiResponse<T>.error(
          _extractMessage(data, fallback: 'Server error'),
          statusCode: error.response?.statusCode,
          errors: data is Map ? data['errors'] : null,
        );
      default:
        return ApiResponse<T>.error(error.message ?? 'Unknown error occurred');
    }
  }

  /// Safely extracts a human-readable message from a Dio response body.
  ///
  /// Handles every shape the API may return:
  ///   - `null` → fallback
  ///   - `String` → used directly
  ///   - `List` → joined with spaces (validation errors)
  ///   - `Map` → reads `message` / `error` keys and recursively normalizes
  ///   - anything else → `toString()`
  String _extractMessage(dynamic data, {required String fallback}) {
    if (data == null) return fallback;
    if (data is String) return data.isEmpty ? fallback : data;
    if (data is List) {
      return data.isEmpty ? fallback : data.join(' ');
    }
    if (data is Map) {
      final raw = data['message'] ?? data['error'];
      if (raw == null) return fallback;
      if (raw is List) return raw.isEmpty ? fallback : raw.join(' ');
      final s = raw.toString();
      return s.isEmpty ? fallback : s;
    }
    return data.toString();
  }
}
