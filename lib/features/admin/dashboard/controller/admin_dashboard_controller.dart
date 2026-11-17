import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/model/admin_dashboard.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/dashboard/service/admin_dashboard_service.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/shared/controller/admin_access.dart';

final adminDashboardProvider = FutureProvider.autoDispose
    .family<AdminDashboard, AdminOwner>((ref, owner) {
      final service = ref.watch(adminDashboardServiceProvider);
      return loadAdmin(ref, owner, service.get);
    }, retry: (_, _) => null);
