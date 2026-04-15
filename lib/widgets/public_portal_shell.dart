import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PublicPortalScaffold extends StatelessWidget {
  const PublicPortalScaffold({
    super.key,
    required this.child,
    required this.actions,
    this.onBrandTap,
    this.contentAlignment = Alignment.centerLeft,
    this.maxContentWidth = 460,
  });

  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBrandTap;
  final Alignment contentAlignment;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 18,
                vertical: isWide ? 28 : 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 20 : 14,
                      vertical: isWide ? 14 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        _BrandBadge(onTap: onBrandTap),
                        const Spacer(),
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: contentAlignment,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: 24,
                          bottom: isWide ? 24 : 12,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PublicPortalPanel extends StatelessWidget {
  const PublicPortalPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kNavy.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kNavy.withValues(alpha: 0.8)),
      ),
      child: child,
    );
  }
}

class PublicPortalHeaderButton extends StatelessWidget {
  const PublicPortalHeaderButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(
          horizontal: filled ? 18 : 14,
          vertical: filled ? 10 : 8,
        ),
      ),
      minimumSize: WidgetStateProperty.all(const Size(88, 40)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: WidgetStateProperty.all(
        filled ? kMaroon : Colors.transparent,
      ),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      side: WidgetStateProperty.all(
        BorderSide(color: filled ? kMaroon : Colors.white),
      ),
    );

    return filled
        ? FilledButton(
            style: style,
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          )
        : OutlinedButton(
            style: style,
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          );
  }
}

class PublicPortalPill extends StatelessWidget {
  const PublicPortalPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: kMaroon.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kMaroon.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.96),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

InputDecoration publicPortalInputDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
    prefixIcon: Icon(icon, color: Colors.white70),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kMaroon, width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/lnu.png', height: 38, width: 38),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BPED MANAGEMENT SYSTEM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isWide ? 14 : 12,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Leyte Normal University',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
