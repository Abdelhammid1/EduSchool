import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTypography {
  static TextTheme cairo(TextTheme base) {
    return GoogleFonts.cairoTextTheme(base).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
  }
}
