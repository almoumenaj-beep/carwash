import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/storage/session_storage.dart';
import '../domain/me.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(sessionStorageProvider)),
);

/// Sign-in, PIN switching and the current user. Every failure is thrown as an [ApiProblem].
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SessionStorage _storage;

  /// The signed-in user, or null when there is no valid session on this device.
  Future<Me?> currentUser() async {
    if (await _storage.token() == null) {
      return null;
    }

    try {
      final response = await _send(() => _dio.get<Map<String, dynamic>>('/me'));
      return Me.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on ApiProblem catch (problem) {
      if (problem.isUnauthenticated || problem.isForbidden) {
        await _storage.clearToken();
        return null;
      }
      rethrow;
    }
  }

  Future<Me> signIn({required String login, required String password}) async {
    final response = await _send(() async => _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {
            'login': login,
            'password': password,
            'device_identifier': await _storage.deviceIdentifier(),
            'device_name': _deviceName,
            'platform': _platform,
          },
          options: _unauthenticated,
        ));

    final data = response.data!['data'] as Map<String, dynamic>;
    await _storage.saveToken(data['token'] as String);
    await _storage.saveDeviceSecret((data['device'] as Map<String, dynamic>)['secret'] as String);

    return Me.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Whether a password login has registered this device, which enables PIN switching.
  Future<bool> isTrustedDevice() async => await _storage.deviceSecret() != null;

  Future<List<DeviceStaff>> deviceStaff() async {
    final response = await _send(() async => _dio.post<Map<String, dynamic>>(
          '/auth/device-staff',
          data: await _deviceCredentials(),
          options: _unauthenticated,
        ));

    return [
      for (final staff in response.data!['data'] as List) DeviceStaff.fromJson(staff as Map<String, dynamic>),
    ];
  }

  Future<Me> pinSignIn({required String userId, required String pin}) async {
    final response = await _send(() async => _dio.post<Map<String, dynamic>>(
          '/auth/pin-login',
          data: {...await _deviceCredentials(), 'user_id': userId, 'pin': pin},
          options: _unauthenticated,
        ));

    final data = response.data!['data'] as Map<String, dynamic>;
    await _storage.saveToken(data['token'] as String);

    return Me.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> setPin({required String currentPassword, required String pin}) async {
    await _send(() => _dio.put<void>('/me/pin', data: {
          'current_password': currentPassword,
          'pin': pin,
          'pin_confirmation': pin,
        }));
  }

  /// Ends the session on the server when reachable; the device stays trusted for PIN switching.
  Future<void> signOut() async {
    try {
      await _send(() => _dio.post<void>('/auth/logout'));
    } on ApiProblem {
      // The local session is discarded either way.
    }
    await _storage.clearToken();
  }

  Future<void> forgetSession() => _storage.clearToken();

  static final _unauthenticated = Options(extra: {skipAuth: true});

  Future<Map<String, String>> _deviceCredentials() async => {
        'device_identifier': await _storage.deviceIdentifier(),
        'device_secret': await _storage.deviceSecret() ?? '',
      };

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (exception) {
      throw ApiProblem.fromDioException(exception);
    }
  }

  static String get _platform => switch (kIsWeb ? null : defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => 'web',
      };

  static String get _deviceName => switch (_platform) {
        'android' => 'Android device',
        'ios' => 'iPhone / iPad',
        _ => 'Web browser',
      };
}
