import 'package:flutter/material.dart';

/// Temporary stand-in for screens not yet ported from Compose.
/// Wired into the router so navigation works end-to-end; replace with the
/// full screen implementation (see the matching *Screen.kt in the Android
/// source) in a follow-up pass.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, this.icon = Icons.construction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              '$title — قيد التطوير',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
