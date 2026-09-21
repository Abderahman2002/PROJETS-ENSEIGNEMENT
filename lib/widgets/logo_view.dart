import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Mirrors ui/components/LogoView.kt. [onTitleClick] preserves the
/// 4-consecutive-tap developer-login gesture from the original app.
class LogoView extends StatelessWidget {
  final double iconSize;
  final bool showSubtitle;
  final VoidCallback? onTitleClick;

  const LogoView({
    super.key,
    this.iconSize = 85,
    this.showSubtitle = true,
    this.onTitleClick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.school, color: Colors.white, size: iconSize * 0.5),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTitleClick,
          child: const Text(
            'رفيق المعلم الموريتاني',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          const Text(
            'مساعدك التربوي اليومي',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
