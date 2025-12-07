import 'package:flutter/material.dart';

enum VaultTab {
  dashboard,
  bens,
}

class VaultNavigationBar extends StatelessWidget {
  const VaultNavigationBar({super.key, required this.currentTab});

  final VaultTab currentTab;

  static const _tabs = <VaultTab>[
    VaultTab.dashboard,
    VaultTab.bens,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = _tabs.indexOf(currentTab);
    return NavigationBar(
      backgroundColor: const Color(0xFF161A1E),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        final tab = _tabs[index];
        final route = _routeFor(tab);
        if (route == null) return;
        FocusScope.of(context).unfocus();
        Navigator.of(context).pushReplacementNamed(route);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.shield_outlined),
          selectedIcon: Icon(Icons.shield),
          label: 'Vault',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Patrimônio',
        ),
      ],
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
    );
  }

  String? _routeFor(VaultTab tab) {
    switch (tab) {
      case VaultTab.dashboard:
        return '/dashboard';
      case VaultTab.bens:
        return '/bens';
    }
  }
}
