class ApiResponse<T> {
  final bool? success;
  final String? message;
  final T? data;
  final int? statusCode;
  final String? error;
  final Map<String, dynamic>? errors;

  ApiResponse({
    this.success,
    this.message,
    this.data,
    this.statusCode,
    this.error,
    this.errors,
  });


  /// [fromJsonT] is a function that converts JSON to T.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      statusCode: json['statusCode'] as int?,
      error: json['error'] as String?,
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'] as Map)
          : null,
    );
  }

  /// [toJsonT] is a function that converts T to JSON.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    final val = <String, dynamic>{
      'success': success,
      'message': message,
      'statusCode': statusCode,
      'error': error,
      'errors': errors,
    };

    if (data != null) {
      val['data'] = toJsonT(data as T);
    } else {
      val['data'] = null;
    }

    return val;
  }

  factory ApiResponse.success(T? data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(
    String error, {
    int? statusCode,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
      errors: errors,
    );
  }

  factory ApiResponse.networkError() {
    return ApiResponse<T>(
      success: false,
      error: 'Network connection failed',
      statusCode: -1,
    );
  }

  factory ApiResponse.timeout() {
    return ApiResponse<T>(
      success: false,
      error: 'Request timeout',
      statusCode: -2,
    );
  }
}
