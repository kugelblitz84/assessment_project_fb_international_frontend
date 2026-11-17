import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_models.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/service/payment_service.dart';

final paymentConfigProvider = FutureProvider.autoDispose<PaymentConfig>((
  ref,
) async {
  final service = ref.watch(paymentServiceProvider);
  final response = await ApiErrorHandler.run(service.config);
  if (!response.success) throw ApiFailure(response.errorCode!);
  return response.data!;
}, retry: (_, _) => null);
