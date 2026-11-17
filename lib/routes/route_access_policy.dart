import 'app_routes.dart';

/// Shared route classification and validation for all internal return locations.
abstract final class RouteAccessPolicy {
  static final _service = RegExp(r'^/services/[^/]+$');
  static final _booking = RegExp(r'^/services/[^/]+/book$');
  static final _bookingDetails = RegExp(r'^/bookings/[^/]+(?:/confirmation)?$');

  static bool requiresAuthentication(String path) =>
      path == AppRoutes.myBookingsPath ||
      path == AppRoutes.editProfilePath ||
      _booking.hasMatch(path) ||
      _bookingDetails.hasMatch(path);

  static String? validateDestination(String? value) {
    if (value == null ||
        value.isEmpty ||
        RegExp(r'[\\\x00-\x20\x7f]').hasMatch(value)) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        !value.startsWith('/') ||
        value.startsWith('//')) {
      return null;
    }
    // Reject encoded separators, traversal and control characters as well.
    try {
      for (final segment in uri.pathSegments) {
        if (segment == '.' ||
            segment == '..' ||
            RegExp(r'[/\\\x00-\x1f\x7f%]').hasMatch(segment)) {
          return null;
        }
      }
    } on FormatException {
      return null;
    }
    final path = uri.path;
    if (requiresAuthentication(path) ||
        _service.hasMatch(path) ||
        [
          AppRoutes.homePath,
          AppRoutes.profilePath,
          AppRoutes.assistantPath,
          AppRoutes.notFoundPath,
        ].contains(path)) {
      return uri.toString();
    }
    return null;
  }

  static Map<String, String> redirectParameters(Uri uri) {
    final destination = redirectDestination(uri);
    return destination == null ? {} : {'redirect': destination};
  }

  static String? redirectDestination(Uri uri) {
    try {
      final values = uri.queryParametersAll['redirect'];
      if (values == null || values.length != 1) return null;
      return validateDestination(values.single);
    } on FormatException {
      return null;
    }
  }

  static String location(String path, String? destination) => Uri(
    path: path,
    queryParameters: destination == null ? null : {'redirect': destination},
  ).toString();
}
