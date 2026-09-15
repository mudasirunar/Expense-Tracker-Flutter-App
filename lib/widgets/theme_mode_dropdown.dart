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

/// Backward-compatible alias
typedef LiquidGlassThemeDropdown = ThemeModeDropdown;

/// Liquid Glass Dropdown Menu Button for Android and Web.
/// Features in-place morphing geometry, subpixel integer alignment, and deferred theme switching.
class _CrossPlatformThemeMenuButton extends StatefulWidget {
  final ThemeMode currentMode;
  final bool isDark;

  const _CrossPlatformThemeMenuButton({
    required this.currentMode,
    required this.isDark,
  });

  /// Calculates the exact width of the dropdown button for a given theme mode,
  /// ensuring integer pixel alignment and zero layout jumping between
  /// collapsed and expanded states.
  static double calculateButtonWidth(ThemeMode mode, BuildContext context) {
    final label = switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.normal,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    // 12 padding each side (24) + 1 border each side (2) + 19 icon + 8 spacing + text width
    return (53.0 + textPainter.width).ceilToDouble();
  }

  @override
  State<_CrossPlatformThemeMenuButton> createState() =>
      _CrossPlatformThemeMenuButtonState();
}

class _CrossPlatformThemeMenuButtonState
    extends State<_CrossPlatformThemeMenuButton> {
  final LayerLink _link = LayerLink();
  final GlobalKey<_LiquidMenuOverlayState> _menuKey =
      GlobalKey<_LiquidMenuOverlayState>();
  OverlayEntry? _entry;
  bool _open = false;

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final anchorOffset = box.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (ctx) {
        final themeProvider = context.watch<ThemeProvider>();
        final isDark = themeProvider.isCurrentlyDark(context);
        final currentMode = themeProvider.themeMode;

        return _LiquidMenuOverlay(
          key: _menuKey,
          link: _link,
          anchorSize: size,
          anchorOffset: anchorOffset,
          selectedMode: currentMode,
          isDark: isDark,
          onSelect: (mode) {
            _close(targetMode: mode);
          },
          onDismiss: () => _close(),
        );
      },
    );

    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void _close({ThemeMode? targetMode}) {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;

    final state = _menuKey.currentState;
    if (state == null) {
      if (targetMode != null && mounted) {
        context.read<ThemeProvider>().setThemeMode(targetMode);
      }
      entry.remove();
      if (mounted) setState(() => _open = false);
      return;
    }

    state.playClose(targetMode: targetMode).whenComplete(() {
      if (targetMode != null && mounted) {
        context.read<ThemeProvider>().setThemeMode(targetMode);
      }
      entry.remove();
      if (mounted) setState(() => _open = false);
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = widget.currentMode;
    final isDark = widget.isDark;

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
    final buttonWidth =
        _CrossPlatformThemeMenuButton.calculateButtonWidth(currentMode, context);

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: Opacity(
          opacity: _open ? 0.0 : 1.0,
          child: SizedBox(
            width: buttonWidth,
            height: 38.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.compose(
                  outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  inner: ColorFilter.matrix(_saturationMatrix(1.35)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: isDark ? 0.22 : 0.40),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          fontWeight: FontWeight.normal,
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Overlay with saturated blur + smooth cubic morph animation
// ---------------------------------------------------------------------

class _LiquidMenuOverlay extends StatefulWidget {
  final LayerLink link;
  final Size anchorSize;
  final Offset anchorOffset;
  final ThemeMode selectedMode;
  final bool isDark;
  final ValueChanged<ThemeMode> onSelect;
  final VoidCallback onDismiss;

  const _LiquidMenuOverlay({
    super.key,
    required this.link,
    required this.anchorSize,
    required this.anchorOffset,
    required this.selectedMode,
    required this.isDark,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<_LiquidMenuOverlay> createState() => _LiquidMenuOverlayState();
}

class _LiquidMenuOverlayState extends State<_LiquidMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final CurvedAnimation _curved;
  late ThemeMode _activeMode;
  ThemeMode? _closingTargetMode;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _activeMode = widget.selectedMode;
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );
    // Opening: fast start, long gentle settle.
    // Closing: fast start, soft ease-out landing back into the button.
    _curved = CurvedAnimation(
      parent: _c,
      curve: const Cubic(0.32, 0.72, 0.0, 1.0),
      reverseCurve: Curves.easeOutCubic,
    );
    _c.forward();
  }

  TickerFuture playClose({ThemeMode? targetMode}) {
    if (!_closing) {
      setState(() {
        _closing = true;
        if (targetMode != null) {
          _closingTargetMode = targetMode;
          _activeMode = targetMode;
        }
      });
    }
    return _c.reverse();
  }

  void _handleSelect(ThemeMode mode) {
    if (_closing) return;
    _closing = true;
    setState(() {
      _closingTargetMode = mode;
      _activeMode = mode;
    });
    widget.onSelect(mode);
  }

  @override
  void dispose() {
    _curved.dispose();
    _c.dispose();
    super.dispose();
  }

  static const double _menuWidth = 232.0;
  static const double _rowHeight = 46.0;
  double get _expandedHeight => 3 * _rowHeight + 14.0;

  bool _isModeDark(ThemeMode mode, BuildContext context) {
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final targetMode = _closingTargetMode ?? widget.selectedMode;
    final targetIsDark = _isModeDark(targetMode, context);
    final currentIsDark = widget.isDark;

    final (targetIcon, targetColor, targetLabel) = switch (targetMode) {
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

    final currentTextPrimary =
        currentIsDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final targetTextPrimary =
        targetIsDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    final targetWidth =
        _CrossPlatformThemeMenuButton.calculateButtonWidth(targetMode, context);

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (!_closing) widget.onDismiss();
            },
            child: const SizedBox.expand(),
          ),
        ),
        AnimatedBuilder(
          animation: _curved,
          builder: (context, _) {
            final t = _curved.value;
            // Morph width from target button width (or initial anchor width) to menu width.
            final startWidth = widget.anchorSize.width;
            final baseWidth = _closing ? targetWidth : startWidth;
            final width = lerpDouble(baseWidth, _menuWidth, t)!;
            final height = lerpDouble(widget.anchorSize.height, _expandedHeight, t)!;
            final radius = lerpDouble(20.0, 24.0, t)!;

            // Smooth cross-fade between list and collapsed face
            final faceOpacity = ((0.32 - t) / 0.32).clamp(0.0, 1.0);
            final listOpacity = ((t - 0.30) / 0.45).clamp(0.0, 1.0);

            // Morph background, border, and text colors smoothly into target theme
            final bgAlpha = lerpDouble(
              targetIsDark ? 0.22 : 0.40,
              currentIsDark ? 0.30 : 0.46,
              t,
            )!;
            final baseBgColor = Color.lerp(
              targetIsDark ? Colors.black : Colors.white,
              currentIsDark ? Colors.black : Colors.white,
              t,
            )!;
            final effectiveBgColor = baseBgColor.withValues(alpha: bgAlpha);

            final targetBorderColor = targetIsDark
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.12);
            final currentBorderColor = currentIsDark
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.12);
            final effectiveBorderColor =
                Color.lerp(targetBorderColor, currentBorderColor, t)!;

            final effectiveFaceTextColor =
                Color.lerp(targetTextPrimary, currentTextPrimary, t)!;

            final minOffsetX = 8.0 - widget.anchorOffset.dx;
            final desiredOffsetX = widget.anchorSize.width - width;
            final effectiveOffsetX =
                desiredOffsetX < minOffsetX ? minOffsetX : desiredOffsetX;

            return CompositedTransformFollower(
              link: widget.link,
              showWhenUnlinked: false,
              offset: Offset(effectiveOffsetX, 0),
              child: SizedBox(
                width: width,
                height: height,
                child: Material(
                  type: MaterialType.transparency,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: BackdropFilter(
                      filter: ImageFilter.compose(
                        outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        inner: ColorFilter.matrix(_saturationMatrix(1.35)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          color: effectiveBgColor,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(
                                alpha: (currentIsDark ? 0.12 : 0.28) * t,
                              ),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: effectiveBorderColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: lerpDouble(
                                  targetIsDark ? 0.20 : 0.05,
                                  currentIsDark ? 0.24 : 0.06,
                                  t,
                                )!,
                              ),
                              blurRadius: lerpDouble(10.0, 26.0, t)!,
                              offset: Offset(0, lerpDouble(2.0, 8.0, t)!),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Collapsed face — identical geometry and centering to real button
                            if (faceOpacity > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                width: baseWidth,
                                height: widget.anchorSize.height,
                                child: Opacity(
                                  opacity: faceOpacity,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          targetIcon,
                                          size: 19,
                                          color: targetColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          targetLabel,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.normal,
                                            color: effectiveFaceTextColor,
                                            letterSpacing: -0.2,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Expanded list
                            if (listOpacity > 0)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Opacity(
                                  opacity: listOpacity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 7,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _LiquidMenuRow(
                                          title: 'System Default',
                                          icon: CupertinoIcons
                                              .device_phone_portrait,
                                          iconColor: const Color(0xFF007AFF),
                                          selected:
                                              _activeMode == ThemeMode.system,
                                          isDark: currentIsDark,
                                          onTap: () =>
                                              _handleSelect(ThemeMode.system),
                                        ),
                                        const SizedBox(height: 2),
                                        _LiquidMenuRow(
                                          title: 'Light',
                                          icon: _activeMode == ThemeMode.light
                                              ? CupertinoIcons.sun_max_fill
                                              : CupertinoIcons.sun_max,
                                          iconColor: const Color(0xFFFF9500),
                                          selected:
                                              _activeMode == ThemeMode.light,
                                          isDark: currentIsDark,
                                          onTap: () =>
                                              _handleSelect(ThemeMode.light),
                                        ),
                                        const SizedBox(height: 2),
                                        _LiquidMenuRow(
                                          title: 'Dark',
                                          icon: _activeMode == ThemeMode.dark
                                              ? CupertinoIcons.moon_fill
                                              : CupertinoIcons.moon,
                                          iconColor: const Color(0xFF5E5CE6),
                                          selected:
                                              _activeMode == ThemeMode.dark,
                                          isDark: currentIsDark,
                                          onTap: () =>
                                              _handleSelect(ThemeMode.dark),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Interactive row with tactile squish physics
// ---------------------------------------------------------------------

class _LiquidMenuRow extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LiquidMenuRow({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_LiquidMenuRow> createState() => _LiquidMenuRowState();
}

class _LiquidMenuRowState extends State<_LiquidMenuRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.only(left: 17, right: 14, top: 11, bottom: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _pressed
                ? (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.iconColor,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: textPrimary,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                ),
              ),
              if (widget.selected) ...[
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
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Saturation Boost Matrix
// ---------------------------------------------------------------------

List<double> _saturationMatrix(double s) {
  const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
  final sr = (1 - s) * lumR, sg = (1 - s) * lumG, sb = (1 - s) * lumB;
  return [
    sr + s, sg, sb, 0, 0,
    sr, sg + s, sb, 0, 0,
    sr, sg, sb + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
