import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ultra-modern, animated navigation bar item for mobile apps.
/// Features smooth expanding pill transition on selection, haptic feedback,
/// active/inactive icon morphing, and badge counters.
class NavBarItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData? inactiveIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;
  final Color activeColor;
  final Color inactiveColor;
  final Color activeBgColor;
  final Color badgeColor;

  const NavBarItem({
    super.key,
    required this.activeIcon,
    this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFF757575),
    this.activeBgColor = const Color(0xFFFF2D6F),
    this.badgeColor = const Color(0xFFFF2D6F),
  });

  @override
  Widget build(BuildContext context) {
    final currentIcon = isSelected ? activeIcon : (inactiveIcon ?? activeIcon);

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBgColor.withValues(alpha: 0.38),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with Badge
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.05 : 1.0,
                    curve: Curves.easeOutBack,
                    child: Icon(
                      currentIcon,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 22,
                    ),
                  ),

                  // Item / Notification Count Badge
                  if (badgeCount > 0)
                    Positioned(
                      right: isSelected ? -7 : -5,
                      top: isSelected ? -7 : -5,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: 1.0,
                        curve: Curves.elasticOut,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E1E2F) : badgeColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Animated Expanding Text Label (Visible on selection)
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: activeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      fontFamily: 'Outfit',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: isSelected
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
