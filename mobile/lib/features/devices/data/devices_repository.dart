import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) => DevicesRepository(ref.watch(dioProvider)));

final devicesProvider = FutureProvider.autoDispose<List<RegisteredDevice>>(
  (ref) => ref.watch(devicesRepositoryProvider).list(),
);

/// A phone or tablet that has signed in to the car wash.
class RegisteredDevice {
  const RegisteredDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastLoginAt,
    required this.isRevoked,
  });

  factory RegisteredDevice.fromJson(Map<String, dynamic> json) => RegisteredDevice(
    id: json['id'] as String,
    name: json['name'] as String,
    platform: json['platform'] as String?,
    lastLoginAt: DateTime.tryParse(json['last_login_at'] as String? ?? '')?.toLocal(),
    isRevoked: json['is_revoked'] as bool,
  );

  final String id;
  final String name;
  final String? platform;
  final DateTime? lastLoginAt;
  final bool isRevoked;
}

class DevicesRepository {
  DevicesRepository(this._dio);

  final Dio _dio;

  Future<List<RegisteredDevice>> list() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/devices'));
    return [for (final device in unwrapData<List>(response)) RegisteredDevice.fromJson(device as Map<String, dynamic>)];
  }

  Future<void> revoke(String id) async {
    await sendRequest(() => _dio.delete<void>('/devices/$id'));
  }
}
