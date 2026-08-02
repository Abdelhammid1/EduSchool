import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// نقطة وصول الـ API.
/// - في الإنتاج: مرّر --dart-define=API_BASE=https://school.manasety.ai/api
/// - على المحاكي: يختار العنوان تلقائيًا حسب المنصّة
///   • iOS Simulator/جهاز iOS يقاسم شبكة الـ Mac ⇒ localhost:5050
///   • Android Emulator يستخدم الاسم المستعار 10.0.2.2:5050
class Env {
  static const String _override =
      String.fromEnvironment('API_BASE', defaultValue: '');

  static String get apiBase {
    if (_override.isNotEmpty) return _override;
    // Release builds (Xcode Cloud, Play Store) always target production.
    if (kReleaseMode) return 'https://school.manasety.ai/api';
    // Web (dev) falls back to localhost — same origin as `flutter run -d chrome`.
    if (kIsWeb) return 'http://localhost:5050/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5050/api';
    // iOS Simulator, iOS device on same LAN, macOS — Mac's localhost.
    return 'http://localhost:5050/api';
  }

  static const String appFlavor = 'teacher';

  static const String institutionNameAr =
      'مؤسسة الشيخ صالح الشريف للتعليم القرآني';
}
