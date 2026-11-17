import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/network/api_error_handler.dart';
import 'package:assessment_project_fb_international_frontend/core/network/api_failure.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/platform_config.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/service/platform_config_service.dart';

final platformConfigProvider = FutureProvider.autoDispose<PlatformConfig>((
  ref,
) async {
  final service = ref.watch(platformConfigServiceProvider);
  final response = await ApiErrorHandler.run(service.get);
  if (!response.success) throw ApiFailure(response.errorCode!);
  return response.data!;
}, retry: (_, _) => null);
