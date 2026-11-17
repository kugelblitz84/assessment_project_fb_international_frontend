abstract final class ApiEndpoints {
  static const health = '/health/status';
  static const platform = '/platform';
  static const payments = '/payments';
  static const paymentConfig = '/payments/config';
  static const adminPayments = '/admin/payments';
  static String appointmentPayments(String id) =>
      '${resource(appointments, id)}/payments';
  static String payAppointment(String id) =>
      '${resource(appointments, id)}/pay';
  static String reconcilePayment(String id, {bool admin = false}) =>
      '${resource(admin ? adminPayments : payments, id)}/reconcile';
  static const profile = '/users/me';
  static const appointments = '/appointments';
  static String availability(String id) =>
      '${resource(services, id)}/availability';
  static String cancelAppointment(String id) =>
      '${resource(appointments, id)}/cancel';
  static const adminDashboard = '/admin/dashboard';
  static const adminCategories = '/admin/categories';
  static const adminServices = '/admin/services';
  static const adminOffers = '/admin/offers';
  static const adminAppointments = '/admin/appointments';
  static const adminImages = '/admin/media/images';
  static String resource(String collection, String id) =>
      '$collection/${Uri.encodeComponent(id)}';
  static String adminAppointmentStatus(String id) =>
      '${resource(adminAppointments, id)}/status';
  static const assistantChat = '/assistant/chat';
  static const services = '/services';
  static const csrf = '/auth/csrf';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const currentUser = '/auth/me';
}
