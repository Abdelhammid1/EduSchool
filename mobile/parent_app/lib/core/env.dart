import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// نقطة وصول الـ API.
/// - في الإنتاج: مرّر --dart-define=API_BASE=https://school.manasety.ai/api
/// - على المحاكي: يختار العنوان تلقائيًا حسب المنصّة
class Env {
  static const String _override =
      String.fromEnvironment('API_BASE', defaultValue: '');

  static String get apiBase {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:5050/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5050/api';
    return 'http://localhost:5050/api';
  }

  static const String appFlavor = 'parent';

  static const String institutionNameAr =
      'مؤسسة الشيخ صالح الشريف للتعليم القرآني';
}
