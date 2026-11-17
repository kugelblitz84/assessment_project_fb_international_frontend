import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/session/application/session_identity_provider.dart';

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
