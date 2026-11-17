/// A normalized failure carried through AsyncValue without exposing transport
/// exceptions or response bodies to presentation code.
class ApiFailure implements Exception {
  const ApiFailure(this.code);
  final String code;
}
