import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class DashboardNavItem {
  const DashboardNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.header,
    required this.body,
    this.navigationItems = const <DashboardNavItem>[],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.breakpoint = 920,
  });

  final Widget header;
  final Widget body;
  final List<DashboardNavItem> navigationItems;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hasNavigation = navigationItems.isNotEmpty;
    final useRail = hasNavigation && screenWidth >= breakpoint;

    return Scaffold(
      backgroundColor: kBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F9FC), Color(0xFFF0F4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              useRail ? 20 : 12,
              16,
              useRail ? 20 : 12,
              0,
            ),
            child: Column(
              children: [
                header,
                const SizedBox(height: 16),
                Expanded(
                  child: useRail
                      ? Row(
                          children: [
                            _DashboardRail(
                              items: navigationItems,
                              selectedIndex: selectedIndex,
                              onDestinationSelected: onDestinationSelected,
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: body),
                          ],
                        )
                      : body,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: !useRail && hasNavigation
          ? SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kNavyBorder),
                  boxShadow: [
                    BoxShadow(
                      color: kNavy.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  backgroundColor: Colors.transparent,
                  indicatorColor: kNavyTint,
                  surfaceTintColor: Colors.transparent,
                  onDestinationSelected: onDestinationSelected,
                  destinations: navigationItems
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon ?? item.icon),
                          label: item.label,
                        ),
                      )
                      .toList(),
                ),
              ),
            )
          : null,
    );
  }
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    this.avatarUrl,
    this.onProfileTap,
    this.actions = const <Widget>[],
  });

  final String title;
  final String subtitle;
  final IconData fallbackIcon;
  final String? avatarUrl;
  final VoidCallback? onProfileTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final profileSummary = Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: kNavy.withValues(alpha: 0.08),
          backgroundImage: (avatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl?.isEmpty ?? true)
              ? Icon(fallbackIcon, color: kNavy)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kNavy.withValues(alpha: 0.64),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kNavyBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: onProfileTap == null
                ? profileSummary
                : InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onProfileTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: profileSummary,
                    ),
                  ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardActionButton extends StatelessWidget {
  const DashboardActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.tone = kNavy,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: tone, size: 20),
          ),
        ),
      ),
    );
  }
}

class _DashboardRail extends StatelessWidget {
  const _DashboardRail({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<DashboardNavItem> items;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kNavyBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        indicatorColor: kNavyTint,
        selectedIconTheme: const IconThemeData(color: kMaroon),
        unselectedIconTheme: IconThemeData(
          color: kNavy.withValues(alpha: 0.56),
        ),
        selectedLabelTextStyle: const TextStyle(
          color: kNavy,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: kNavy.withValues(alpha: 0.56),
          fontWeight: FontWeight.w700,
        ),
        labelType: NavigationRailLabelType.all,
        leading: const SizedBox(height: 8),
        destinations: items
            .map(
              (item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              ),
            )
            .toList(),
      ),
    );
  }
}
