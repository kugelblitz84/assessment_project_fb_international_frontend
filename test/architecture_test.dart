import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../scripts/check_architecture.dart';

void main() {
  test(
    'source imports respect feature and layer boundaries without cycles',
    () {
      expect(architectureViolations(Directory('lib').absolute), isEmpty);
    },
  );
}
