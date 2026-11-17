import 'dart:typed_data';

import 'package:assessment_project_fb_international_frontend/core/utils/input_validation_exception.dart';

class SelectedImage {
  SelectedImage(Uint8List bytes, this.filename)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView(),
      mimeSubtype = switch (filename.split('.').last.toLowerCase()) {
        'jpg' || 'jpeg' => 'jpeg',
        'png' => 'png',
        'webp' => 'webp',
        _ => throw const InputValidationException(),
      } {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const InputValidationException();
    }
  }
  static const maxBytes = 2 * 1024 * 1024;
  final Uint8List bytes;
  final String filename, mimeSubtype;
}
