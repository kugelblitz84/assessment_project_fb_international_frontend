import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'autocare.access_token';

  @override
  Future<String?> readToken() => _guard(() => _storage.read(key: _tokenKey));

  @override
  Future<void> saveToken(String token) =>
      _guard(() => _storage.write(key: _tokenKey, value: token));

  @override
  Future<void> clearToken() => _guard(() => _storage.delete(key: _tokenKey));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      throw const SecureStorageException();
    }
  }
}
