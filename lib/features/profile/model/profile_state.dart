class ProfileState {
  const ProfileState({this.saving = false, this.errorCode, this.saved = false});
  final bool saving;
  final bool saved;
  final String? errorCode;
}
