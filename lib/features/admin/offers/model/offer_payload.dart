import 'package:assessment_project_fb_international_frontend/features/admin/offers/model/offer_validation.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/model/admin_validation.dart';

class OfferPayload {
  const OfferPayload({
    required this.serviceId,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startsAt,
    required this.endsAt,
    this.isActive = true,
  });
  final String serviceId, title, description, discountType, discountValue;
  final DateTime startsAt, endsAt;
  final bool isActive;
  String? get validationError =>
      AdminValidation.name(title) ??
      AdminValidation.description(description) ??
      OfferValidation.offer(discountType, discountValue, startsAt, endsAt) ??
      (serviceId.isEmpty ? 'Choose a service.' : null);
  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'title': title.trim(),
    'description': description,
    'discountType': discountType,
    'discountValue': discountValue,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'isActive': isActive,
  };
}
