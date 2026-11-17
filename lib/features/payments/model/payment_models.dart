import 'package:assessment_project_fb_international_frontend/core/utils/input_validation_exception.dart';

typedef PaymentJson = Map<String, dynamic>;

class PaymentConfig {
  const PaymentConfig({
    required this.onlinePaymentEnabled,
    required this.sandbox,
    required this.payAtWorkshopEnabled,
  });
  factory PaymentConfig.fromJson(PaymentJson json) {
    if (json['provider'] != 'sslcommerz') {
      throw const FormatException('Unsupported gateway.');
    }
    return PaymentConfig(
      onlinePaymentEnabled: json['onlinePaymentEnabled'] as bool,
      sandbox: json['sandbox'] as bool,
      payAtWorkshopEnabled: json['payAtWorkshopEnabled'] as bool,
    );
  }
  final bool onlinePaymentEnabled, sandbox, payAtWorkshopEnabled;
  static const demo = PaymentConfig(
    onlinePaymentEnabled: false,
    sandbox: true,
    payAtWorkshopEnabled: true,
  );
}

enum PaymentStatus {
  initiating,
  pending,
  paid,
  failed,
  cancelled,
  expired,
  reviewRequired;

  static PaymentStatus parse(String value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    throw const FormatException('Invalid payment status.');
  }

  String get apiValue => this == reviewRequired ? 'review_required' : name;
  bool get unresolved =>
      this == initiating || this == pending || this == reviewRequired;
  String get label => this == reviewRequired ? 'Manual review required' : name;
}

class PaymentAttempt {
  PaymentAttempt.fromJson(PaymentJson json)
    : paymentId = json['paymentId'] as String,
      appointmentId = json['appointmentId'] as String,
      provider = json['provider'] as String,
      status = PaymentStatus.parse(json['status'] as String),
      amount = json['amount'] as num,
      currency = json['currency'] as String,
      checkoutUrl = json['checkoutUrl'] as String?,
      paidAt = _date(json['paidAt']),
      applied = json['applied'] as bool,
      reasonCode = json['reasonCode'] as String?,
      createdAt = DateTime.parse(json['createdAt'] as String),
      updatedAt = DateTime.parse(json['updatedAt'] as String) {
    if (provider != 'sslcommerz' ||
        currency != 'BDT' ||
        !amount.isFinite ||
        amount < 0) {
      throw const FormatException('Invalid payment response.');
    }
  }
  final String paymentId, appointmentId, provider, currency;
  final PaymentStatus status;
  final num amount;
  final String? checkoutUrl, reasonCode;
  final DateTime? paidAt;
  final DateTime createdAt, updatedAt;
  final bool applied;
  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

class GatewayIncident {
  GatewayIncident.fromJson(PaymentJson json)
    : validationId = json['validationId'] as String?,
      bankTransactionId = json['bankTransactionId'] as String?,
      reasonCode = json['reasonCode'] as String;
  final String? validationId, bankTransactionId;
  final String reasonCode;
}

/// Admin responses deliberately have no checkout URL.
class AdminPayment {
  AdminPayment.fromJson(PaymentJson json)
    : attempt = PaymentAttempt.fromJson({...json, 'checkoutUrl': null}),
      merchantTransactionId = json['merchantTransactionId'] as String,
      validationId = json['validationId'] as String?,
      bankTransactionId = json['bankTransactionId'] as String?,
      customerName = (json['customer'] as Map)['name'] as String,
      customerEmail = (json['customer'] as Map)['email'] as String,
      serviceName = json['serviceName'] as String,
      lastReconciledAt = PaymentAttempt._date(json['lastReconciledAt']),
      incidents = List.unmodifiable(
        (json['gatewayIncidents'] as List).map(
          (row) =>
              GatewayIncident.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      );
  final PaymentAttempt attempt;
  final String merchantTransactionId, customerName, customerEmail, serviceName;
  final String? validationId, bankTransactionId;
  final DateTime? lastReconciledAt;
  final List<GatewayIncident> incidents;
}

class CheckoutContact {
  CheckoutContact({
    required String phone,
    required String address,
    required String city,
    required String postcode,
  }) : phone = phone.trim(),
       address = address.trim(),
       city = city.trim(),
       postcode = postcode.trim();
  final String phone, address, city, postcode;
  static String? validate(String field, String? input) {
    final value = input?.trim() ?? '';
    if (field == 'phone') {
      return RegExp(r'^\+?[0-9]{7,19}$').hasMatch(value)
          ? null
          : 'Enter 7–19 digits, optionally starting with +.';
    }
    final max = field == 'postcode' ? 30 : 50;
    return value.isEmpty || value.length > max
        ? 'Enter 1–$max characters.'
        : null;
  }

  PaymentJson toJson() {
    final json = {
      'phone': phone,
      'address': address,
      'city': city,
      'postcode': postcode,
    };
    for (final entry in json.entries) {
      if (validate(entry.key, entry.value) != null) {
        throw const InputValidationException();
      }
    }
    return json;
  }
}

Uri trustedCheckoutUri(String value, PaymentConfig config) {
  final uri = Uri.tryParse(value);
  final hosts = config.sandbox
      ? {'sandbox.sslcommerz.com', 'sandbox-gw.sslcommerz.com'}
      : {'securepay.sslcommerz.com', 'engine.sslcommerz.com'};
  if (!config.onlinePaymentEnabled ||
      uri == null ||
      uri.scheme != 'https' ||
      !hosts.contains(uri.host) ||
      uri.userInfo.isNotEmpty ||
      uri.port != 443) {
    throw const FormatException('Untrusted checkout URL.');
  }
  return uri;
}
