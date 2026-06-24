import 'package:flutter/material.dart';

/// شعار المؤسسة (شعار + اسم) — يستخدم في شاشات تسجيل الدخول والأخطاء.
class ManasetyLogo extends StatelessWidget {
  final double size;
  final ManasetyLogoVariant variant;
  final Color? background;

  const ManasetyLogo({
    super.key,
    this.size = 120,
    this.variant = ManasetyLogoVariant.vertical,
    this.background,
  });

  String get _asset {
    switch (variant) {
      case ManasetyLogoVariant.emblem:
        return 'assets/images/logo-emblem.png';
      case ManasetyLogoVariant.horizontal:
        return 'assets/images/logo-horizontal.png';
      case ManasetyLogoVariant.vertical:
        return 'assets/images/logo-vertical.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      _asset,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
    if (background == null) return img;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: img,
    );
  }
}

enum ManasetyLogoVariant { emblem, horizontal, vertical }
