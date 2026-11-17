import 'api_endpoints.dart';

class BackendPolicy {
  BackendPolicy(this.base);
  final Uri base;
  String get path => base.path.replaceFirst(RegExp(r'/+$'), '');
  bool trusted(Uri uri) =>
      uri.origin == base.origin &&
      (path.isEmpty || uri.path.startsWith('$path/'));
  bool isAuthEndpoint(Uri uri) =>
      [
        ApiEndpoints.login,
        ApiEndpoints.register,
        ApiEndpoints.refresh,
        ApiEndpoints.logout,
      ].any(
        (endpoint) =>
            uri.path.replaceFirst(RegExp(r'/+$'), '') == '$path$endpoint',
      );
}
