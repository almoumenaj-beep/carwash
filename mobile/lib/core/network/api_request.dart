import 'package:dio/dio.dart';

import 'api_problem.dart';

/// Runs a Dio request and rethrows any failure as an [ApiProblem].
Future<Response<T>> sendRequest<T>(Future<Response<T>> Function() request) async {
  try {
    return await request();
  } on DioException catch (exception) {
    throw ApiProblem.fromDioException(exception);
  }
}

/// The `data` member of a JSON:API-style envelope (`{"data": ...}`).
T unwrapData<T>(Response<Map<String, dynamic>> response) => response.data!['data'] as T;
