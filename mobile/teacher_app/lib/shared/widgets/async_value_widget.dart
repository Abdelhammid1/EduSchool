import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import 'error_view.dart';

/// مغلّف عام يكشف AsyncValue ويعرض حالات التحميل/الخطأ/البيانات.
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.navy),
      ),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}
