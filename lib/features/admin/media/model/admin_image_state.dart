import 'dart:typed_data';

class AdminImageState {
  AdminImageState({
    this.url,
    Uint8List? bytes,
    this.name,
    this.busy = false,
    this.errorCode,
  }) : bytes = bytes?.asUnmodifiableView();
  final String? url, name, errorCode;
  final Uint8List? bytes;
  final bool busy;
}
