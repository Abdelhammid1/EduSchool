/// نقطة وصول الـ API. القيمة الافتراضية تستخدم محاكي أندرويد (10.0.2.2) للتطوير.
/// للبناء الإنتاجي مرّر: --dart-define=API_BASE=https://manasety-school.sd/api
class Env {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:5050/api',
  );

  static const String appFlavor = 'teacher';

  static const String institutionNameAr =
      'مؤسسة الشيخ صالح الشريف للتعليم القرآني';
}
