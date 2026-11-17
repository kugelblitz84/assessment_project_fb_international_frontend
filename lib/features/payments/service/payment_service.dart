import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/demo_mode.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/request_access.dart';
import '../../../core/session/application/session_identity_provider.dart';
import '../model/payment_models.dart';

final paymentServiceProvider = Provider(
  (ref) => PaymentService(ref.watch(dioProvider)),
);
final paymentConfigProvider = FutureProvider.autoDispose<PaymentConfig>(
  (ref) async => ref.watch(demoModeProvider)
      ? PaymentConfig.demo
      : await ref.watch(paymentServiceProvider).config(),
  retry: (_, _) => null,
);

class PaymentService {
  PaymentService(this.dio);
  final Dio dio;
  Future<PaymentConfig> config() async => PaymentConfig.fromJson(
    (await dio.get<PaymentJson>(
      ApiEndpoints.paymentConfig,
      options: Options(extra: {requestAccessKey: RequestAccess.public}),
    )).data!,
  );
  Future<List<PaymentAttempt>> history(String id) async {
    final response = await dio.get<List<dynamic>>(
      ApiEndpoints.appointmentPayments(id),
    );
    return List.unmodifiable(
      response.data!.map(
        (row) => PaymentAttempt.fromJson(Map<String, dynamic>.from(row as Map)),
      ),
    );
  }

  Future<PaymentAttempt> get(String id) async => PaymentAttempt.fromJson(
    (await dio.get<PaymentJson>(
      ApiEndpoints.resource(ApiEndpoints.payments, id),
    )).data!,
  );
  Future<PaymentAttempt> initiate(String id, CheckoutContact contact) async =>
      PaymentAttempt.fromJson(
        (await dio.post<PaymentJson>(
          ApiEndpoints.payAppointment(id),
          data: contact.toJson(),
        )).data!,
      );
  Future<PaymentAttempt> reconcile(String id) async => PaymentAttempt.fromJson(
    (await dio.post<PaymentJson>(ApiEndpoints.reconcilePayment(id))).data!,
  );
}

final reconciliationGateProvider = Provider((ref) {
  ref.watch(sessionIdentityProvider);
  return ReconciliationGate();
});

/// Shared by customer and admin routes so remounts cannot bypass spacing.
class ReconciliationGate {
  ReconciliationGate({DateTime Function()? now}) : now = now ?? DateTime.now;
  final DateTime Function() now;
  final _busy = <String>{};
  final _last = <String, DateTime>{};
  Future<T?> run<T>(String id, Future<T> Function() action) async {
    final last = _last[id];
    if (_busy.contains(id) ||
        (last != null && now().difference(last) < const Duration(seconds: 5))) {
      return null;
    }
    _busy.add(id);
    _last[id] = now();
    try {
      return await action();
    } finally {
      _last[id] = now();
      _busy.remove(id);
    }
  }
}
