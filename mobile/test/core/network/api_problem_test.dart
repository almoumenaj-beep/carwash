import 'package:carwash_app/core/network/api_problem.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = RequestOptions(path: '/auth/login');

  test('reads a validation problem with its field errors', () {
    final problem = ApiProblem.fromDioException(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 422,
          data: {
            'type': 'urn:carwash:problem:validation-failed',
            'title': 'البيانات المرسلة غير صالحة',
            'status': 422,
            'detail': 'حقل كلمة المرور مطلوب.',
            'instance': '/api/v1/auth/login',
            'errors': {
              'password': ['حقل كلمة المرور مطلوب.'],
            },
          },
        ),
      ),
    );

    expect(problem.isValidation, isTrue);
    expect(problem.status, 422);
    expect(problem.fieldError('password'), 'حقل كلمة المرور مطلوب.');
    expect(problem.fieldError('login'), isNull);
  });

  test('reads a problem sent as a JSON string', () {
    final problem = ApiProblem.fromDioException(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 429,
          data: '{"type":"urn:carwash:problem:too-many-requests","title":"Too many requests","status":429,"detail":"Too Many Attempts.","retry_after":42}',
        ),
      ),
    );

    expect(problem.type, 'urn:carwash:problem:too-many-requests');
    expect(problem.retryAfter, 42);
  });

  test('treats a request without a response as a network problem', () {
    final problem = ApiProblem.fromDioException(
      DioException(requestOptions: request, type: DioExceptionType.connectionError),
    );

    expect(problem.isNetwork, isTrue);
  });

  test('keeps the status of a non-JSON error response', () {
    final problem = ApiProblem.fromDioException(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 502, statusMessage: 'Bad Gateway', data: '<html>'),
      ),
    );

    expect(problem.type, 'about:blank');
    expect(problem.status, 502);
  });
}
