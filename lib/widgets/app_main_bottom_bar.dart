import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_bar.dart';

/// Wires [AppBottomBar] to go_router navigation for the 5 tab screens
/// (Home, Classes/"sections", Chat, Bag, Profile) — mirrors the bottomBar
/// wiring in MainActivity.kt's RafiqAlMuallimApp.
class AppMainBottomBar extends StatelessWidget {
  final BottomTab current;

  const AppMainBottomBar({super.key, required this.current});

  static const _routes = {
    BottomTab.home: '/home',
    BottomTab.sections: '/classes',
    BottomTab.chat: '/chat',
    BottomTab.bag: '/bag',
    BottomTab.profile: '/profile',
  };

  @override
  Widget build(BuildContext context) {
    return AppBottomBar(
      currentTab: current,
      onTabSelected: (tab) {
        if (tab == current) return;
        context.go(_routes[tab]!);
      },
    );
  }
}
