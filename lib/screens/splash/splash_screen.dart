import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/logo_view.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onTimeout;

  const SplashScreen({super.key, required this.onTimeout});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), widget.onTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceBackground,
      body: const Center(
        child: LogoView(iconSize: 96, showSubtitle: true),
      ),
    );
  }
}
