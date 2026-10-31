import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// An API error in RFC 9457 problem-details form, as returned by every `/api` endpoint.
///
/// Branch on [type]; show [detail] (already translated by the server) to the user.
class ApiProblem implements Exception {
  const ApiProblem({
    required this.type,
    required this.title,
    required this.status,
    required this.detail,
    this.errors = const {},
    this.retryAfter,
  });

  /// The connection failed or timed out, so the server never answered.
  const ApiProblem.network()
    : type = networkType,
      title = '',
      status = 0,
      detail = '',
      errors = const {},
      retryAfter = null;

  /// The app itself failed, e.g. it could not read a response; shown as a generic error.
  const ApiProblem.unexpected()
    : type = unexpectedType,
      title = '',
      status = 0,
      detail = '',
      errors = const {},
      retryAfter = null;

  /// [error] as a problem to show. Anything that is not an [ApiProblem] is a bug in the app:
  /// it is reported to the Flutter error log instead of vanishing, and shown as a generic error.
  static ApiProblem from(Object error, [StackTrace? stackTrace]) {
    if (error is ApiProblem) {
      return error;
    }

    FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'carwash'));

    return const ApiProblem.unexpected();
  }

  factory ApiProblem.fromJson(Map<String, dynamic> json, {int? status}) {
    final errors = <String, List<String>>{};
    final rawErrors = json['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((field, messages) {
        errors['$field'] = [for (final message in messages as List) '$message'];
      });
    }

    return ApiProblem(
      type: json['type'] as String? ?? 'about:blank',
      title: json['title'] as String? ?? '',
      status: json['status'] as int? ?? status ?? 0,
      detail: json['detail'] as String? ?? json['message'] as String? ?? '',
      errors: errors,
      retryAfter: json['retry_after'] as int?,
    );
  }

  factory ApiProblem.fromDioException(DioException exception) {
    final response = exception.response;
    if (response == null) {
      return const ApiProblem.network();
    }

    var data = response.data;
    if (data is String && data.isNotEmpty) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        data = null;
      }
    }

    if (data is Map<String, dynamic>) {
      return ApiProblem.fromJson(data, status: response.statusCode);
    }

    return ApiProblem(
      type: 'about:blank',
      title: response.statusMessage ?? '',
      status: response.statusCode ?? 0,
      detail: '',
    );
  }

  static const typePrefix = 'urn:carwash:problem:';
  static const networkType = '${typePrefix}network';
  static const unexpectedType = '${typePrefix}client-error';

  final String type;
  final String title;
  final int status;
  final String detail;
  final Map<String, List<String>> errors;
  final int? retryAfter;

  bool get isNetwork => type == networkType;
  bool get isValidation => type == '${typePrefix}validation-failed';
  bool get isUnauthenticated => type == '${typePrefix}unauthenticated';
  bool get isForbidden => type == '${typePrefix}forbidden';

  /// The first validation message for [field], if any.
  String? fieldError(String field) => errors[field]?.first;

  @override
  String toString() => 'ApiProblem($status $type: $detail)';
}
