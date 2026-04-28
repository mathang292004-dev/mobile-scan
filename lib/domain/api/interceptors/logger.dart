import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

enum LogLevel { none, basic, headers, body }

class LoggerInterceptor extends Interceptor {
  final LogLevel level;
  final int maxBodyLength;
  final Set<String> maskHeaders;

  LoggerInterceptor({
    this.level = LogLevel.body,
    this.maxBodyLength = 3000,
    Set<String>? maskHeaders,
  }) : maskHeaders = maskHeaders ??
      {'authorization', 'cookie', 'set-cookie', 'x-api-key'};

  String _maskHeader(String key, dynamic value) {
    if (value == null) return 'null';
    if (maskHeaders.contains(key.toLowerCase())) return '***';
    return value.toString();
  }

  String _prettyPrintBody(dynamic data) {
    try {
      if (data == null) return 'null';
      if (data is FormData) {
        return 'FormData(${data.fields.length} fields, ${data.files.length} files)';
      }
      if (data is String) {
        // try decode JSON
        final decoded = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      // If it's already a Map/List
      if (data is Map || data is List) {
        final pretty = const JsonEncoder.withIndent('  ').convert(data);
        return pretty;
      }
      // Fallback to toString()
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }

  String _maybeTruncate(String text) {
    if (text.length <= maxBodyLength) return text;
    return '${text.substring(0, maxBodyLength)}... (truncated, ${text.length} chars)';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (level == LogLevel.none) return handler.next(options);

    final buffer = StringBuffer();
    buffer.writeln('┌────── Request ──────');
    buffer.writeln('${options.method} ${options.uri}');

    if (level.index >= LogLevel.headers.index) {
      buffer.writeln('Headers:');
      options.headers.forEach((k, v) => buffer.writeln('  $k: ${_maskHeader(k, v)}'));
    }

    if (level.index >= LogLevel.body.index) {
      buffer.writeln('QueryParameters: ${options.queryParameters}');
      final body = _prettyPrintBody(options.data);
      buffer.writeln('Body: ${_maybeTruncate(body)}');
    }

    buffer.writeln('└─────────────────────');
    // Use print or any logger you prefer
    debugPrint(buffer.toString());

    // Attach a timestamp so we can measure duration in onResponse/onError
    options.extra['__logger_start'] = DateTime.now().millisecondsSinceEpoch;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (level == LogLevel.none) return handler.next(response);

    final start = response.requestOptions.extra['__logger_start'] as int?;
    final durationMs = start != null
        ? (DateTime.now().millisecondsSinceEpoch - start)
        : null;

    String formatDuration(int ms) {
      if (ms >= 1000) {
        final seconds = ms / 1000;
        // If it’s a whole number, show without decimals
        if (seconds == seconds.roundToDouble()) {
          return "${seconds.toInt()}s";
        } else {
          return "${seconds.toStringAsFixed(1)}s";
        }
      } else {
        return "${ms}ms";
      }
    }


    final buffer = StringBuffer();
    buffer.writeln('┌───── Response (${response.statusCode}) ─────');
    buffer.writeln('${response.requestOptions.method} ${response.requestOptions.uri}');
    if (durationMs != null) {
      buffer.writeln('Duration: ${formatDuration(durationMs)}');
    }

    if (level.index >= LogLevel.headers.index) {
      buffer.writeln('Headers:');
      response.headers.forEach((k, v) => buffer.writeln('  $k: ${_maskHeader(k, v.join(', '))}'));
    }

    if (level.index >= LogLevel.body.index) {
      final body = _prettyPrintBody(response.data);
      buffer.writeln('Body: ${_maybeTruncate(body)}');
    }

    buffer.writeln('└─────────────────────────');
    debugPrint(buffer.toString());

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (level == LogLevel.none) return handler.next(err);

    final req = err.requestOptions;
    final start = req.extra['__logger_start'] as int?;
    final durationMs = start != null ? (DateTime.now().millisecondsSinceEpoch - start) : null;

    final buffer = StringBuffer();
    buffer.writeln('┌────── Error ──────');
    buffer.writeln('${req.method} ${req.uri}');
    if (durationMs != null) buffer.writeln('Duration: $durationMs ms');
    buffer.writeln('Error: ${err.type} ${err.message}');

    if (err.response != null) {
      buffer.writeln('Status: ${err.response?.statusCode}');
      if (level.index >= LogLevel.body.index) {
        final body = _prettyPrintBody(err.response?.data);
        buffer.writeln('Response body: ${_maybeTruncate(body)}');
      }
    }

    buffer.writeln('└──────────────────────');
    debugPrint(buffer.toString());

    handler.next(err);
  }
}
