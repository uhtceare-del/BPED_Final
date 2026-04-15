import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class DashboardModulePage extends StatelessWidget {
  const DashboardModulePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.floatingActionButton,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? floatingActionButton;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final defaultLeading = Navigator.canPop(context)
        ? IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: kNavy),
            tooltip: 'Back',
          )
        : null;

    return Stack(
      children: [
        Column(
          children: [
            DashboardModuleHeader(
              title: title,
              subtitle: subtitle,
              leading: leading ?? defaultLeading,
              trailing: trailing,
            ),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
        if (floatingActionButton != null)
          Positioned(right: 0, bottom: 0, child: floatingActionButton!),
      ],
    );
  }
}

class DashboardModuleHeader extends StatelessWidget {
  const DashboardModuleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNavyBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: kNavy.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = kNavy,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kNavyBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 42, color: tone),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kNavy.withValues(alpha: 0.62),
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 18), action!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTag extends StatelessWidget {
  const DashboardTag({
    super.key,
    required this.label,
    this.color = kNavy,
    this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kNavyBorder),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
