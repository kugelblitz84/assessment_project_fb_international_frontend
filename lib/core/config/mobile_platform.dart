import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool get isNativeMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
