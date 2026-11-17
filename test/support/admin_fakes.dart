import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:assessment_project_fb_international_frontend/core/config/api_config.dart';
import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/core/network/dio_provider.dart';
import 'package:assessment_project_fb_international_frontend/core/session/application/session_providers.dart';
import 'package:assessment_project_fb_international_frontend/core/session/data/user_model.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/auth_session.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/user_entity.dart';
import 'package:assessment_project_fb_international_frontend/demo/demo_auth.dart';
import 'package:assessment_project_fb_international_frontend/features/admin/media/controller/admin_image_controller.dart';

import 'session_fakes.dart';

const categoryId = 'c1000000-0000-4000-8000-000000000001';
const serviceId = 'c2000000-0000-4000-8000-000000000001';
const packageId = 'c2000000-0000-4000-8000-000000000002';
const appointmentId = 'c3000000-0000-4000-8000-000000000001';
const adminJson = {
  'id': 'admin-1',
  'name': 'Assessment Admin',
  'email': 'admin@example.test',
  'role': 'ADMIN',
};
final adminUser = UserModel.fromJson(adminJson);
const categoryJson = {
  'id': categoryId,
  'name': 'Care',
  'slug': 'care',
  'description': '',
  'imageUrl': null,
  'isActive': true,
  'sortOrder': 0,
};
Map<String, dynamic> serviceJson({bool package = false}) => {
  'id': package ? packageId : serviceId,
  'name': package ? 'Care package' : 'Exterior wash',
  'slug': package ? 'care-package' : 'exterior-wash',
  'description': 'Hand wash',
  'categoryId': categoryId,
  'categoryName': 'Care',
  'type': package ? 'PACKAGE' : 'INDIVIDUAL',
  'price': 500,
  'originalPrice': 500,
  'effectivePrice': 500,
  'currency': 'BDT',
  'durationMinutes': 30,
  'imageUrl': null,
  'inclusions': ['Wash'],
  'available': true,
  'isFeatured': false,
  'isActive': true,
  'sortOrder': 0,
  'packageItems': package
      ? [
          {
            'serviceId': serviceId,
            'name': 'Exterior wash',
            'quantity': 2,
            'available': true,
          },
        ]
      : [],
};
Map<String, dynamic> appointmentJson({String status = 'pending'}) => {
  'id': appointmentId,
  'serviceName': 'Exterior wash',
  'user': {'name': 'Customer', 'email': 'customer@example.test'},
  'startsAt': '2026-11-17T02:00:00Z',
  'endsAt': '2026-11-17T02:30:00Z',
  'status': status,
  'basePrice': 500,
  'price': 450,
  'currency': 'BDT',
  'durationMinutes': 30,
  'createdAt': '2026-11-16T12:00:00Z',
  'cancelledAt': null,
  'vehicle': null,
  'appliedOfferId': null,
  'paymentStatus': 'unpaid',
  'paymentMethod': null,
  'canPayOnline': true,
  'canCancel': status == 'pending' || status == 'confirmed',
};
const offerJson = {
  'id': 'c4000000-0000-4000-8000-000000000001',
  'serviceId': serviceId,
  'title': 'Wash offer',
  'description': '',
  'discountType': 'PERCENTAGE',
  'discountValue': 10,
  'startsAt': '2026-11-17T00:00:00Z',
  'endsAt': '2026-11-18T00:00:00Z',
  'isActive': true,
};

/// Transport fixture only; this never contacts a live backend.
class AdminAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final uploads = <List<int>>[];
  int? failStatus;
  int? mutationStatus;
  String appointmentStatus = 'pending';
  Completer<void>? mutationGate;
  final mutationStarted = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      if (options.path.endsWith('/media/images')) uploads.add(bytes);
    }
    var status = failStatus ?? 200;
    Object? body;
    if (options.method != 'GET') {
      if (!mutationStarted.isCompleted) mutationStarted.complete();
      await mutationGate?.future;
      status = failStatus ?? mutationStatus ?? 200;
      if (options.path.endsWith('/status')) {
        if (status == 200) {
          appointmentStatus = (options.data as Map)['status'] as String;
        } else {
          appointmentStatus = 'cancelled';
        }
      }
      body = options.path.endsWith('/media/images')
          ? {
              'imageUrl':
                  'https://api.example.test/api/v1/media/images/$serviceId',
            }
          : {};
      if (options.path == '/users/me') {
        body = {
          'user': {
            ...adminJson,
            ...Map<String, dynamic>.from(options.data as Map),
          },
        };
      }
    } else if (options.path.endsWith('/dashboard')) {
      body = {
        for (final key in [
          'totalServices',
          'activeServices',
          'totalCategories',
          'totalPackages',
          'activeOffers',
          'pendingAppointments',
          'confirmedAppointments',
          'completedAppointments',
        ])
          key: 3,
      };
    } else if (options.path.endsWith('/categories')) {
      body = [categoryJson];
    } else if (options.path.contains('/categories/')) {
      body = categoryJson;
    } else if (options.path.endsWith('/services')) {
      body = [serviceJson(), serviceJson(package: true)];
    } else if (options.path.contains('/services/')) {
      body = serviceJson(package: options.path.contains(packageId));
    } else if (options.path.endsWith('/offers')) {
      body = [offerJson];
    } else if (options.path.contains('/offers/')) {
      body = offerJson;
    } else if (options.path.endsWith('/appointments')) {
      body = [appointmentJson(status: appointmentStatus)];
    } else if (options.path.contains('/appointments/')) {
      body = appointmentJson(status: appointmentStatus);
    } else {
      body = [];
    }
    return ResponseBody.fromString(
      jsonEncode(status >= 400 ? {'message': 'Private server details'} : body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ProviderContainer adminContainer({
  required AdminAdapter adapter,
  bool authenticated = true,
  UserEntity? user,
  Future<XFile?> Function()? imagePicker,
}) {
  final repository = StubAuthRepository()
    ..currentUserGate = (Completer<UserEntity>()..complete(user ?? adminUser))
    ..authenticationSession = AuthSession(
      accessToken: 'admin-token',
      user: user ?? adminUser,
    );
  final container = ProviderContainer.test(
    overrides: [
      if (imagePicker != null)
        adminImagePickerProvider.overrideWithValue(imagePicker),
      demoModeProvider.overrideWithValue(true),
      apiBaseUrlProvider.overrideWithValue('https://api.example.test/api/v1'),
      tokenStorageProvider.overrideWithValue(
        MemoryTokenStorage(authenticated ? 'admin-token' : null),
      ),
      authRepositoryProvider.overrideWithValue(repository),
      cookieTransportProvider.overrideWithValue(DemoCookieTransport()),
    ],
  );
  container.read(dioProvider).httpClientAdapter = adapter;
  container.read(authTransportProvider).httpClientAdapter = adapter;
  return container;
}
