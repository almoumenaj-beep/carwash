import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/offer.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) => OffersRepository(ref.watch(dioProvider)));

final offersProvider = FutureProvider.autoDispose<List<Offer>>((ref) => ref.watch(offersRepositoryProvider).offers());

class OffersRepository {
  OffersRepository(this._dio);

  final Dio _dio;

  Future<List<Offer>> offers() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/offers'));
    return [for (final offer in unwrapData<List>(response)) Offer.fromJson(offer as Map<String, dynamic>)];
  }

  Future<void> save({String? id, required String title, String? description, int? price, String? expiresOn, bool? isActive}) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'expires_on': expiresOn,
      'is_active': ?isActive,
    };
    await sendRequest(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('/offers', data: data)
          : _dio.patch<Map<String, dynamic>>('/offers/$id', data: data),
    );
  }

  Future<void> delete(String id) async {
    await sendRequest(() => _dio.delete<Map<String, dynamic>>('/offers/$id'));
  }
}
