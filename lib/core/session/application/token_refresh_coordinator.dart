import '../domain/token_storage.dart';
import '../domain/session_exception.dart';

class TokenRefreshCoordinator {
  TokenRefreshCoordinator(this.storage, this.renew, this.clearCookies);
  final TokenStorage storage;
  final Future<String> Function() renew;
  final Future<void> Function() clearCookies;
  Future<String>? _pending;
  int generation = 0;
  bool enabled = true;
  void Function()? onInvalidSession;
  void invalidate() {
    generation++;
    enabled = false;
  }

  Future<void> drain() async {
    try {
      await _pending;
    } catch (_) {}
  }

  Future<String> refresh({String? failedToken}) async {
    if (!enabled) throw const InvalidSessionException();
    final epoch = generation;
    final current = await storage.readToken();
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
      final token = await renew();
      if (epoch != generation) throw const InvalidSessionException();
      await storage.saveToken(token);
      if (epoch != generation) {
        await storage.clearToken();
        throw const InvalidSessionException();
      }
      return token;
    } on InvalidSessionException {
      if (epoch == generation) {
        invalidate();
        await storage.clearToken();
        await clearCookies();
        onInvalidSession?.call();
      }
      rethrow;
    }
  }
}
