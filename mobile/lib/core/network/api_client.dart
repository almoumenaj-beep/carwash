import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../l10n/locale_controller.dart';
import '../storage/session_storage.dart';

/// Request `extra` flag for sign-in calls that must not carry the stored token.
const skipAuth = 'skipAuth';

/// Called when an authenticated request is rejected with 401, e.g. after the device was revoked.
typedef UnauthorizedHandler = void Function();

final unauthorizedHandlerProvider = Provider<UnauthorizedHandler>((ref) => () {});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['Accept-Language'] = ref.read(localeProvider).languageCode;

        final token = options.extra[skipAuth] == true ? null : await ref.read(sessionStorageProvider).token();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) {
        final sentToken = error.requestOptions.headers.containsKey('Authorization');
        if (sentToken && error.response?.statusCode == 401) {
          ref.read(unauthorizedHandlerProvider)();
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});
