import 'package:assessment_project_fb_international_frontend/core/session/domain/session_exception.dart';
import 'package:assessment_project_fb_international_frontend/core/session/domain/token_storage.dart';

class TokenRefreshCoordinator {
  TokenRefreshCoordinator(this._storage, this._renew, this._clearCookies);
  final TokenStorage _storage;
  final Future<String> Function() _renew;
  final Future<void> Function() _clearCookies;
  Future<String>? _pending;
  int _generation = 0;
  bool _enabled = true;
  int get generation => _generation;
  bool get enabled => _enabled;
  void enable() => _enabled = true;
  void Function()? onInvalidSession;
  void invalidate() {
    _generation++;
    _enabled = false;
  }

  Future<void> drain() async {
    try {
      await _pending;
    } catch (_) {}
  }

  Future<String> refresh({String? failedToken}) async {
    if (!enabled) throw const InvalidSessionException();
    final epoch = generation;
    final current = await _storage.readToken();
    if (epoch != generation) throw const InvalidSessionException();
    if (failedToken != null && current != null && current != failedToken) {
      return current;
    }
    if (_pending != null) return _pending!;
    final operation = _perform(epoch);
    _pending = operation;
    try {
      return await operation;
    } finally {
      if (identical(_pending, operation)) _pending = null;
    }
  }

  Future<String> _perform(int epoch) async {
    try {
      final token = await _renew();
      if (epoch != generation) throw const InvalidSessionException();
      await _storage.saveToken(token);
      if (epoch != generation) {
        await _storage.clearToken();
        throw const InvalidSessionException();
      }
      return token;
    } on InvalidSessionException {
      if (epoch == generation) {
        invalidate();
        try {
          await _storage.clearToken();
        } finally {
          try {
            await _clearCookies();
          } finally {
            onInvalidSession?.call();
          }
        }
      }
      rethrow;
    }
  }
}
