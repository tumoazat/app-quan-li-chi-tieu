import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final inactiveColor = Colors.grey;

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AnimatedNavItem(
              icon: Icons.home_rounded,
              label: 'Trang chủ',
              route: '/home',
              currentRoute: currentRoute,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/home');
              },
            ),
            _AnimatedNavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Giao dịch',
              route: '/transactions',
              currentRoute: currentRoute,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/transactions');
              },
            ),
            const SizedBox(width: 56),
            _AnimatedNavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Thống kê',
              route: '/statistics',
              currentRoute: currentRoute,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/statistics');
              },
            ),
            _AnimatedNavItem(
              icon: Icons.person_rounded,
              label: 'Cá nhân',
              route: '/profile',
              currentRoute: currentRoute,
              activeColor: primaryColor,
              inactiveColor: inactiveColor,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/profile');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _AnimatedNavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentRoute == widget.route;
    final color = isActive ? widget.activeColor : widget.inactiveColor;

    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                height: 3,
                width: isActive ? 20 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isActive ? widget.activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Icon with scale animation
              AnimatedScale(
                scale: isActive ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? widget.activeColor.withOpacity(0.12) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Label with animated opacity
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
