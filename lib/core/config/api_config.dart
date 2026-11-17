import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiBaseUrlProvider = Provider<String>((ref) {
  const configured = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://fb-international-assessment-project.onrender.com/api/v1',
  );
  final uri = Uri.tryParse(configured);
  if (uri == null ||
      !{'https', 'http'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw StateError('API_BASE_URL must be an absolute HTTP(S) API URL.');
  }
  return configured.replaceFirst(RegExp(r'/+$'), '');
});
