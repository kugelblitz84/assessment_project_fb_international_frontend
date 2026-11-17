abstract final class AppRoutes {
  static const adminPath = '/admin';
  static const adminCategoriesPath = '/admin/categories';
  static const adminServicesPath = '/admin/services';
  static const adminPackagesPath = '/admin/packages';
  static const adminOffersPath = '/admin/offers';
  static const adminAppointmentsPath = '/admin/appointments';
  static String adminEditLocation(String path, String id) =>
      '$path/${Uri.encodeComponent(id)}/edit';
  static const login = 'login';
  static const loginPath = '/login';
  static const register = 'register';
  static const registerPath = '/register';
  static const home = 'home';
  static const homePath = '/home';
  static const serviceDetails = 'serviceDetails';
  static const serviceDetailsPath = '/services/:serviceId';
  static const booking = 'booking';
  static const bookingPath = '/services/:serviceId/book';
  static const bookingConfirmation = 'bookingConfirmation';
  static const bookingConfirmationPath = '/bookings/:bookingId/confirmation';
  static const myBookings = 'myBookings';
  static const myBookingsPath = '/bookings';
  static const bookingDetails = 'bookingDetails';
  static const bookingDetailsPath = '/bookings/:bookingId';
  static const profile = 'profile';
  static const profilePath = '/profile';
  static const editProfile = 'editProfile';
  static const editProfilePath = '/profile/edit';
  static const assistant = 'assistant';
  static const assistantPath = '/assistant';
  static const notFound = 'notFound';
  static const notFoundPath = '/not-found';

  static String serviceDetailsLocation(String serviceId) =>
      '/services/${Uri.encodeComponent(serviceId)}';
  static String bookingLocation(String serviceId) =>
      '${serviceDetailsLocation(serviceId)}/book';
  static String bookingDetailsLocation(String bookingId) =>
      '/bookings/${Uri.encodeComponent(bookingId)}';
  static String bookingConfirmationLocation(String bookingId) =>
      '${bookingDetailsLocation(bookingId)}/confirmation';
}
