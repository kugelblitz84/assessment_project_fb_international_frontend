import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/session/application/session_controller.dart';
import '../../../../core/session/application/session_identity_provider.dart';
import '../../../../core/session/domain/auth_state.dart';
import '../../../shared/controller/catalog_controller.dart';
import '../../../shared/controller/appointments_controller.dart';
import '../../../booking/controller/booking_controller.dart';
import '../model/admin_models.dart';
import '../service/admin_repository.dart';

// Watching both identity and role clears private results on logout, account
// replacement, and role changes. No admin provider uses the demo adapter.
final adminAccessProvider = Provider.autoDispose((ref) {
  ref.watch(sessionIdentityProvider);
  final auth = ref.watch(sessionProvider).asData?.value;
  return auth is Authenticated && auth.user.isAdmin;
});

Future<T> _load<T>(
  Ref ref,
  AdminOwner owner,
  Future<T> Function(AdminRepository) load,
) async {
  ref.watch(sessionIdentityProvider);
  if (owner != ref.watch(adminOwnerProvider) || !owner.authorized) {
    throw const AdminFailure('FORBIDDEN');
  }
  final repository = ref.watch(adminRepositoryProvider);
  final result = await ApiErrorHandler.run(() => load(repository));
  if (!result.success) throw AdminFailure(result.errorCode!);
  return result.data as T;
}

// A new owner gets a new provider instance, with no retained AsyncValue data
// from the previous account. Old instances auto-dispose when their UI leaves.
typedef AdminOwner = ({SessionIdentity identity, bool authorized});
final adminOwnerProvider = Provider.autoDispose<AdminOwner>(
  (ref) => (
    identity: ref.watch(sessionIdentityProvider),
    authorized: ref.watch(adminAccessProvider),
  ),
);
typedef AdminResourceKey = ({AdminOwner owner, String id});
typedef AppointmentFilter = ({String? status, String? date});
typedef AdminAppointmentKey = ({AdminOwner owner, AppointmentFilter filter});

final adminDashboardProvider = FutureProvider.autoDispose
    .family<Json, AdminOwner>(
      (ref, owner) =>
          _load(ref, owner, (r) => r.get(ApiEndpoints.adminDashboard)),
      retry: (_, _) => null,
    );
final adminCategoriesProvider = FutureProvider.autoDispose
    .family<List<AdminCategory>, AdminOwner>(
      (ref, owner) => _load(
        ref,
        owner,
        (r) => r.list(ApiEndpoints.adminCategories, AdminCategory.fromJson),
      ),
      retry: (_, _) => null,
    );
final adminCategoryProvider = FutureProvider.autoDispose
    .family<AdminCategory, AdminResourceKey>(
      (ref, key) => _load(
        ref,
        key.owner,
        (r) async => AdminCategory.fromJson(
          await r.get(
            ApiEndpoints.resource(ApiEndpoints.adminCategories, key.id),
          ),
        ),
      ),
      retry: (_, _) => null,
    );
final adminServicesProvider = FutureProvider.autoDispose
    .family<List<AdminService>, AdminOwner>(
      (ref, owner) => _load(
        ref,
        owner,
        (r) => r.list(ApiEndpoints.adminServices, AdminService.fromJson),
      ),
      retry: (_, _) => null,
    );
final adminServiceProvider = FutureProvider.autoDispose
    .family<AdminService, AdminResourceKey>(
      (ref, key) => _load(
        ref,
        key.owner,
        (r) async => AdminService.fromJson(
          await r.get(
            ApiEndpoints.resource(ApiEndpoints.adminServices, key.id),
          ),
        ),
      ),
      retry: (_, _) => null,
    );
final adminOffersProvider = FutureProvider.autoDispose
    .family<List<AdminOffer>, AdminOwner>(
      (ref, owner) => _load(
        ref,
        owner,
        (r) => r.list(ApiEndpoints.adminOffers, AdminOffer.fromJson),
      ),
      retry: (_, _) => null,
    );
final adminOfferProvider = FutureProvider.autoDispose
    .family<AdminOffer, AdminResourceKey>(
      (ref, key) => _load(
        ref,
        key.owner,
        (r) async => AdminOffer.fromJson(
          await r.get(ApiEndpoints.resource(ApiEndpoints.adminOffers, key.id)),
        ),
      ),
      retry: (_, _) => null,
    );
final adminAppointmentsProvider = FutureProvider.autoDispose
    .family<List<AdminAppointment>, AdminAppointmentKey>(
      (ref, key) => _load(
        ref,
        key.owner,
        (r) => r.list(
          ApiEndpoints.adminAppointments,
          AdminAppointment.fromJson,
          query: {
            if (key.filter.status != null) 'status': key.filter.status,
            if (key.filter.date != null) 'date': key.filter.date,
          },
        ),
      ),
      retry: (_, _) => null,
    );
final adminAppointmentProvider = FutureProvider.autoDispose
    .family<AdminAppointment, AdminResourceKey>(
      (ref, key) => _load(
        ref,
        key.owner,
        (r) async => AdminAppointment.fromJson(
          await r.get(
            ApiEndpoints.resource(ApiEndpoints.adminAppointments, key.id),
          ),
        ),
      ),
      retry: (_, _) => null,
    );

class AdminFailure implements Exception {
  const AdminFailure(this.code);
  final String code;
  @override
  String toString() => ApiErrorHandler.messageFor(code);
}

final adminMutationProvider = NotifierProvider.autoDispose<AdminMutation, bool>(
  AdminMutation.new,
);

class AdminMutation extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(sessionIdentityProvider);
    ref.watch(adminAccessProvider);
    return false;
  }

  Future<ApiResponse<void>> save(String path, Json payload, {String? id}) =>
      _run(
        (r) => r.save(path, payload, id: id),
        collection: path,
        resourceId: id,
      );
  Future<ApiResponse<void>> transition(String id, String status) =>
      _run((r) => r.transition(id, status), appointmentId: id);

  Future<ApiResponse<void>> _run(
    Future<void> Function(AdminRepository) action, {
    String? appointmentId,
    String? collection,
    String? resourceId,
  }) async {
    if (state || !ref.read(adminAccessProvider)) {
      return const ApiResponse.failure('FORBIDDEN');
    }
    final identity = ref.read(sessionIdentityProvider);
    state = true;
    final result = await ApiErrorHandler.run(
      () => action(ref.read(adminRepositoryProvider)),
    );
    if (!ref.mounted ||
        identity != ref.read(sessionIdentityProvider) ||
        !ref.read(adminAccessProvider)) {
      return const ApiResponse.failure('UNAUTHORIZED');
    }
    state = false;
    if (result.success) {
      ref.invalidate(adminDashboardProvider);
      if (collection != null) {
        ref.invalidate(catalogControllerProvider);
        ref.invalidate(adminServicesProvider);
        if (collection == ApiEndpoints.adminCategories) {
          ref.invalidate(adminCategoriesProvider);
          ref.invalidate(adminServiceProvider);
          if (resourceId != null) {
            ref.invalidate(
              adminCategoryProvider((
                owner: ref.read(adminOwnerProvider),
                id: resourceId,
              )),
            );
          }
        }
        if (collection == ApiEndpoints.adminServices && resourceId != null) {
          ref.invalidate(
            adminServiceProvider((
              owner: ref.read(adminOwnerProvider),
              id: resourceId,
            )),
          );
        }
        if (collection == ApiEndpoints.adminOffers) {
          ref.invalidate(adminOffersProvider);
          ref.invalidate(adminServiceProvider);
          if (resourceId != null) {
            ref.invalidate(
              adminOfferProvider((
                owner: ref.read(adminOwnerProvider),
                id: resourceId,
              )),
            );
          }
        }
      }
    }
    if (appointmentId != null &&
        (result.success || result.errorCode == 'CONFLICT')) {
      ref.invalidate(
        adminAppointmentProvider((
          owner: ref.read(adminOwnerProvider),
          id: appointmentId,
        )),
      );
      ref.invalidate(adminAppointmentsProvider);
      ref.invalidate(adminDashboardProvider);
      ref.invalidate(appointmentsControllerProvider);
      ref.invalidate(appointmentDetailsProvider(appointmentId));
      ref.invalidate(bookingControllerProvider);
    }
    return result;
  }
}
