abstract final class AppRoutes {
  static const bootstrap = 'bootstrap';
  static const bootstrapPath = '/';
  static const onboarding = 'onboarding';
  static const onboardingPath = '/onboarding';
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
  static const bootstrapError = 'bootstrapError';
  static const bootstrapErrorPath = '/bootstrap-error';
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
