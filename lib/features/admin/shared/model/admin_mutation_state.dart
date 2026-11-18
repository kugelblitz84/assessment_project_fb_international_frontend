/// Immutable state shared by admin resource editors. Request results remain
/// available to the initiating view; provider state drives busy/error rendering.
class AdminMutationState {
  const AdminMutationState({this.busy = false, this.errorCode});

  final bool busy;
  final String? errorCode;
}
