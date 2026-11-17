import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:assessment_project_fb_international_frontend/core/config/demo_mode.dart';
import 'package:assessment_project_fb_international_frontend/features/appointments/model/appointment_model.dart';
import 'package:assessment_project_fb_international_frontend/features/catalog/model/service_model.dart';
import 'package:assessment_project_fb_international_frontend/features/payments/model/payment_summary.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/model/availability_model.dart';
import 'package:assessment_project_fb_international_frontend/features/workshop/utils/workshop_calendar.dart';

final demoWorkshopProvider = Provider<DemoWorkshop?>(
  (ref) => ref.watch(demoModeProvider) ? DemoWorkshop() : null,
);

/// Deliberately isolated sample backend. Nothing is persisted or sent over HTTP.
class DemoWorkshop {
  static const timeZone = 'Asia/Dhaka · UTC+06:00';
  static DateTime get today {
    return WorkshopCalendar.today();
  }

  static const services = <ServiceModel>[
    ServiceModel(
      id: 'exterior-wash',
      name: 'Exterior wash',
      categoryId: 'cleaning',
      categoryName: 'Cleaning',
      description:
          'A fresh start for your daily drive. A careful exterior clean that lifts road dust and leaves your car looking its best.',
      price: 650,
      currency: 'BDT',
      durationMinutes: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&w=900&q=80',
      inclusions: [
        'Exterior foam wash',
        'Wheel and tyre cleaning',
        'Microfibre hand dry',
      ],
    ),
    ServiceModel(
      id: 'interior-detail',
      name: 'Interior detailing',
      categoryId: 'detailing',
      categoryName: 'Detailing',
      description:
          'Give your cabin a little attention. A thorough clean for the surfaces, seats and small spaces you spend time with every day.',
      price: 2500,
      currency: 'BDT',
      durationMinutes: 120,
      imageUrl:
          'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?auto=format&fit=crop&w=900&q=80',
      inclusions: [
        'Interior vacuum',
        'Dashboard and console cleaning',
        'Seat and upholstery care',
      ],
    ),
    ServiceModel(
      id: 'oil-change',
      name: 'Engine oil change',
      categoryId: 'maintenance',
      categoryName: 'Maintenance',
      description:
          'Keep your engine running smoothly with an oil and filter change. The workshop will confirm the correct oil specification for your car.',
      price: 3200,
      currency: 'BDT',
      durationMinutes: 60,
      imageUrl:
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=900&q=80',
      inclusions: [
        'Engine oil replacement',
        'Oil filter replacement',
        'Fluid level check',
      ],
    ),
    ServiceModel(
      id: 'ac-inspection',
      name: 'AC inspection',
      categoryId: 'inspection',
      categoryName: 'Inspection',
      description:
          'Less cooling than usual? Have your air conditioning checked before deciding on repairs or replacement parts.',
      price: 800,
      currency: 'BDT',
      durationMinutes: 45,
      inclusions: [
        'Cooling performance check',
        'Vent and airflow inspection',
        'Inspection findings explained',
      ],
    ),
    ServiceModel(
      id: 'battery-check',
      name: 'Battery health check',
      categoryId: 'inspection',
      categoryName: 'Inspection',
      description:
          'Understand the condition of your battery and charging system with a workshop inspection.',
      price: 400,
      currency: 'BDT',
      durationMinutes: 30,
      inclusions: [
        'Battery voltage test',
        'Terminal inspection',
        'Charging system check',
      ],
    ),
    ServiceModel(
      id: 'tyre-inspection',
      name: 'Tyre & safety inspection',
      categoryId: 'inspection',
      categoryName: 'Inspection',
      description:
          'Plan your next journey with a tyre and basic safety inspection. A technician will explain any issues that need further attention.',
      price: 600,
      currency: 'BDT',
      durationMinutes: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=900&q=80',
      inclusions: [
        'Tyre pressure and tread check',
        'Visible wear inspection',
        'Basic safety checks',
      ],
    ),
  ];

  final Map<String, List<AppointmentModel>> _appointments = {};
  final Map<String, TimeSlotModel> _slots = {};
  int _sequence = 100;
  Future<void> pause() =>
      Future<void>.delayed(const Duration(milliseconds: 220));

  AvailabilityModel availability(String serviceId, DateTime day) {
    final slots = <TimeSlotModel>[];
    for (final hour in [9, 10, 11, 13, 14, 15, 16]) {
      final local = DateTime(day.year, day.month, day.day, hour);
      final instant = DateTime.utc(
        day.year,
        day.month,
        day.day,
        hour,
      ).subtract(WorkshopCalendar.utcOffset);
      final id = '$serviceId-${day.year}-${day.month}-${day.day}-$hour';
      final taken = _appointments.values
          .expand((items) => items)
          .any((a) => a.slot.id == id && a.status != BookingStatus.cancelled);
      final slot = TimeSlotModel(
        id: id,
        startsAt: instant,
        workshopTime: local,
        timeZone: timeZone,
        available: instant.isAfter(DateTime.now()) && !taken,
      );
      _slots[id] = slot;
      slots.add(slot);
    }
    return AvailabilityModel(
      date: day,
      timeZone: timeZone,
      slots: List.unmodifiable(slots),
    );
  }

  List<AppointmentModel> appointments(String userId) => List.unmodifiable(
    _appointments.putIfAbsent(
      userId,
      () => [
        _sample(
          '$userId-AC1042',
          services[0],
          today.add(const Duration(days: 2)),
          10,
          BookingStatus.pending,
        ),
        _sample(
          '$userId-AC1038',
          services[2],
          today.add(const Duration(days: 5)),
          14,
          BookingStatus.confirmed,
        ),
        _sample(
          '$userId-AC0986',
          services[1],
          today.subtract(const Duration(days: 14)),
          11,
          BookingStatus.completed,
        ),
        _sample(
          '$userId-AC0974',
          services[4],
          today.subtract(const Duration(days: 30)),
          9,
          BookingStatus.cancelled,
        ),
      ],
    ),
  );

  AppointmentModel _sample(
    String id,
    ServiceModel service,
    DateTime day,
    int hour,
    BookingStatus status,
  ) => AppointmentModel(
    id: id,
    serviceId: service.id,
    serviceName: service.name,
    slot: TimeSlotModel(
      id: '${service.id}-${day.year}-${day.month}-${day.day}-$hour',
      startsAt: DateTime.utc(
        day.year,
        day.month,
        day.day,
        hour,
      ).subtract(WorkshopCalendar.utcOffset),
      workshopTime: DateTime(day.year, day.month, day.day, hour),
      timeZone: timeZone,
    ),
    status: status,
    canCancel: status == BookingStatus.pending,
    paymentStatus: PaymentSummary.unpaid,
    paymentMethod: null,
    canPayOnline: false,
    price: service.price,
    currency: service.currency,
    durationMinutes: service.durationMinutes,
  );

  AppointmentModel? appointment(String userId, String id) {
    for (final item in appointments(userId)) {
      if (item.id == id) return item;
    }
    return null;
  }

  AppointmentModel? create(String userId, String serviceId, String slotId) {
    appointments(userId);
    final slot = _slots[slotId];
    if (slot == null ||
        !slot.available ||
        !slot.startsAt.isAfter(DateTime.now())) {
      return null;
    }
    if (_appointments.values
        .expand((items) => items)
        .any(
          (a) => a.slot.id == slotId && a.status != BookingStatus.cancelled,
        )) {
      return null;
    }
    final service = services.firstWhere((s) => s.id == serviceId);
    final result = AppointmentModel(
      id: 'DEMO-${++_sequence}',
      serviceId: service.id,
      serviceName: service.name,
      slot: slot,
      status: BookingStatus.pending,
      canCancel: true,
      paymentStatus: PaymentSummary.unpaid,
      paymentMethod: null,
      canPayOnline: false,
      price: service.price,
      currency: service.currency,
      durationMinutes: service.durationMinutes,
    );
    _appointments[userId] = [..._appointments[userId]!, result];
    return result;
  }

  AppointmentModel? cancel(String userId, String id) {
    final original = appointment(userId, id);
    if (original == null || !original.canCancel) return null;
    final result = original.copyWith(status: BookingStatus.cancelled);
    _appointments[userId] = [
      for (final a in _appointments[userId]!)
        if (a.id == id) result else a,
    ];
    return result;
  }
}
