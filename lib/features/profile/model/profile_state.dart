class ProfileState {
  const ProfileState({this.saving = false, this.errorCode});
  final bool saving;
  final String? errorCode;
}
