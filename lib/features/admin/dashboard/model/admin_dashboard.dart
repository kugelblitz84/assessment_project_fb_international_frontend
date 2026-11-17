class AdminDashboard {
  AdminDashboard.fromJson(Map<String, dynamic> json)
    : totalServices = json['totalServices'] as int,
      activeServices = json['activeServices'] as int,
      totalCategories = json['totalCategories'] as int,
      totalPackages = json['totalPackages'] as int,
      activeOffers = json['activeOffers'] as int,
      pendingAppointments = json['pendingAppointments'] as int,
      confirmedAppointments = json['confirmedAppointments'] as int,
      completedAppointments = json['completedAppointments'] as int;
  final int totalServices,
      activeServices,
      totalCategories,
      totalPackages,
      activeOffers,
      pendingAppointments,
      confirmedAppointments,
      completedAppointments;
}
