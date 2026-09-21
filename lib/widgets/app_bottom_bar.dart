import 'package:flutter/material.dart';

/// Mirrors ui/components/AppBottomBar.kt.
enum BottomTab { home, sections, chat, bag, profile }

class AppBottomBar extends StatelessWidget {
  final BottomTab? currentTab;
  final ValueChanged<BottomTab> onTabSelected;

  const AppBottomBar({super.key, required this.currentTab, required this.onTabSelected});

  static const _items = [
    (tab: BottomTab.home, label: 'الرئيسية', icon: Icons.home_outlined, activeIcon: Icons.home),
    (tab: BottomTab.sections, label: 'الأقسام', icon: Icons.school_outlined, activeIcon: Icons.school),
    (tab: BottomTab.chat, label: 'الدردشة', icon: Icons.forum_outlined, activeIcon: Icons.forum),
    (tab: BottomTab.bag, label: 'الحقيبة', icon: Icons.work_outline, activeIcon: Icons.work),
    (tab: BottomTab.profile, label: 'حسابي', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _items.indexWhere((i) => i.tab == currentTab);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onDestinationSelected: (i) => onTabSelected(_items[i].tab),
        destinations: _items
            .map((i) => NavigationDestination(
                  icon: Icon(i.icon),
                  selectedIcon: Icon(i.activeIcon),
                  label: i.label,
                ))
            .toList(),
      ),
    );
  }
}
