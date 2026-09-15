import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Theme selector dropdown:
/// - On iOS devices: embeds Apple's native UIKit UIButton with native UIMenu.
///   When tapped, iOS directly spawns its authentic Liquid Glass menu.
/// - On Android / Web: renders the cross-platform pull-down menu.
class ThemeModeDropdown extends StatelessWidget {
  const ThemeModeDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isCurrentlyDark(context);
    final currentMode = themeProvider.themeMode;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return _NativeIosThemeMenuButton(
        currentMode: currentMode,
        isDark: isDark,
      );
    }

    return _CrossPlatformThemeMenuButton(
      currentMode: currentMode,
      isDark: isDark,
    );
  }
}

/// Native UIKit UIMenu PlatformView for iOS devices.
class _NativeIosThemeMenuButton extends StatefulWidget {
  final ThemeMode currentMode;
  final bool isDark;

  const _NativeIosThemeMenuButton({
    required this.currentMode,
    required this.isDark,
  });

  @override
  State<_NativeIosThemeMenuButton> createState() => _NativeIosThemeMenuButtonState();
}

class _NativeIosThemeMenuButtonState extends State<_NativeIosThemeMenuButton> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant _NativeIosThemeMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode || oldWidget.isDark != widget.isDark) {
      _channel?.invokeMethod('updateMode', {
        'currentMode': widget.currentMode.name,
        'isDark': widget.isDark,
      });
    }
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('com.mudasir.expensetracker/native_theme_menu_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onThemeSelected') {
        final modeString = call.arguments as String?;
        final mode = switch (modeString) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        if (mounted) {
          context.read<ThemeProvider>().setThemeMode(mode);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 36,
      child: UiKitView(
        viewType: 'com.mudasir.expensetracker/native_theme_menu',
        creationParams: {
          'currentMode': widget.currentMode.name,
          'isDark': widget.isDark,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}

/// Custom Frosted Liquid Glass Dropdown Menu Button for Android and Web.
class _CrossPlatformThemeMenuButton extends StatelessWidget {
  final ThemeMode currentMode;
  final bool isDark;

  const _CrossPlatformThemeMenuButton({
    required this.currentMode,
    required this.isDark,
  });

  void _openMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    Navigator.of(context).push(
      _LiquidGlassMenuRoute(
        buttonRect: offset & size,
        currentMode: currentMode,
        isDark: isDark,
        onSelected: (mode) {
          context.read<ThemeProvider>().setThemeMode(mode);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (currentIcon, currentColor, currentLabel) = switch (currentMode) {
      ThemeMode.system => (
          CupertinoIcons.device_phone_portrait,
          const Color(0xFF007AFF),
          'System',
        ),
      ThemeMode.light => (
          CupertinoIcons.sun_max_fill,
          const Color(0xFFFF9500),
          'Light',
        ),
      ThemeMode.dark => (
          CupertinoIcons.moon_fill,
          const Color(0xFF5E5CE6),
          'Dark',
        ),
    };

    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMenu(context),
        borderRadius: BorderRadius.circular(22),
        splashColor: currentColor.withValues(alpha: 0.15),
        highlightColor: currentColor.withValues(alpha: 0.08),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0x3D1E293B),
                          const Color(0x240F172A),
                        ]
                      : [
                          const Color(0x4DFFFFFF),
                          const Color(0x2EFFFFFF),
                        ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.50),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentIcon,
                    size: 19,
                    color: currentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Route presenting the floating liquid glass menu expanding directly over the button.
class _LiquidGlassMenuRoute extends PopupRoute<void> {
  final Rect buttonRect;
  final ThemeMode currentMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onSelected;

  _LiquidGlassMenuRoute({
    required this.buttonRect,
    required this.currentMode,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.05);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss theme menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _LiquidGlassMenuPopup(
      buttonRect: buttonRect,
      currentMode: currentMode,
      isDark: isDark,
      onSelected: onSelected,
      animation: animation,
    );
  }
}

class _LiquidGlassMenuPopup extends StatelessWidget {
  final Rect buttonRect;
  final ThemeMode currentMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onSelected;
  final Animation<double> animation;

  const _LiquidGlassMenuPopup({
    required this.buttonRect,
    required this.currentMode,
    required this.isDark,
    required this.onSelected,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    const menuWidth = 208.0;
    const estimatedHeight = 168.0;

    // Position directly OVER the button so the button seamlessly morphs into the menu
    final double top = (buttonRect.top - 4).clamp(
      padding.top + 6,
      screenSize.height - estimatedHeight - 12,
    );

    final double left = (buttonRect.right - menuWidth).clamp(
      10.0,
      screenSize.width - menuWidth - 10.0,
    );

    // Springy liquid curve with overshoot bounce
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    return Stack(
      children: [
        Positioned(
          top: top,
          left: left,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.78, end: 1.0).animate(curved),
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      width: menuWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0x3D1E293B),
                                  const Color(0x240F172A),
                                ]
                              : [
                                  const Color(0x4DFFFFFF),
                                  const Color(0x2EFFFFFF),
                                ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.50),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GlassMenuItem(
                            title: 'System Default',
                            icon: CupertinoIcons.device_phone_portrait,
                            iconColor: const Color(0xFF007AFF),
                            isSelected: currentMode == ThemeMode.system,
                            isDark: isDark,
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelected(ThemeMode.system);
                            },
                          ),
                          const SizedBox(height: 2),
                          _GlassMenuItem(
                            title: 'Light',
                            icon: currentMode == ThemeMode.light
                                ? CupertinoIcons.sun_max_fill
                                : CupertinoIcons.sun_max,
                            iconColor: const Color(0xFFFF9500),
                            isSelected: currentMode == ThemeMode.light,
                            isDark: isDark,
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelected(ThemeMode.light);
                            },
                          ),
                          const SizedBox(height: 2),
                          _GlassMenuItem(
                            title: 'Dark',
                            icon: currentMode == ThemeMode.dark
                                ? CupertinoIcons.moon_fill
                                : CupertinoIcons.moon,
                            iconColor: const Color(0xFF5E5CE6),
                            isSelected: currentMode == ThemeMode.dark,
                            isDark: isDark,
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelected(ThemeMode.dark);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// An individual option row inside the floating liquid glass menu.
class _GlassMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassMenuItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: iconColor.withValues(alpha: 0.12),
      highlightColor: iconColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? iconColor : iconColor.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? textPrimary : textMuted,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 7),
              Icon(
                Icons.check_rounded,
                size: 17,
                color: textPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
