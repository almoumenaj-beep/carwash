import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/app_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository(ref.watch(dioProvider)));

final settingsProvider = FutureProvider.autoDispose<AppSettings>((ref) => ref.watch(settingsRepositoryProvider).get());

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<AppSettings> get() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/settings'));
    return AppSettings.fromJson(unwrapData(response));
  }

  Future<AppSettings> update(Map<String, dynamic> changes) async {
    final response = await sendRequest(() => _dio.patch<Map<String, dynamic>>('/settings', data: changes));
    return AppSettings.fromJson(unwrapData(response));
  }
}
