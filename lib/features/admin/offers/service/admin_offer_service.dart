import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_endpoints.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/utils/json_response.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/admin_offer.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_payload.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/resource_activation_payload.dart';

final adminOfferServiceProvider = Provider(
  (ref) => AdminOfferService(ref.watch(dioProvider)),
);

class AdminOfferService {
  AdminOfferService(this._dio);
  final Dio _dio;
  Future<List<AdminOffer>> list() async => jsonList(
    (await _dio.get<Object?>(ApiEndpoints.adminOffers)).data,
    AdminOffer.fromJson,
  );
  Future<AdminOffer> get(String id) async => decodeJson(
    (await _dio.get<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminOffers, id),
    )).data,
    AdminOffer.fromJson,
  );
  Future<void> save(OfferPayload payload, {String? id}) async {
    if (id == null) {
      await _dio.post<Object?>(
        ApiEndpoints.adminOffers,
        data: payload.toJson(),
      );
    } else {
      await _dio.patch<Object?>(
        ApiEndpoints.resource(ApiEndpoints.adminOffers, id),
        data: payload.toJson(),
      );
    }
  }

  Future<void> setActive(String id, bool active) async {
    await _dio.patch<Object?>(
      ApiEndpoints.resource(ApiEndpoints.adminOffers, id),
      data: ResourceActivationPayload(active).toJson(),
    );
  }
}
