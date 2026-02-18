import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A frosted-glass app bar that sits at the top of [SmartScrollView].
///
/// Blurs the content beneath it and renders a top-to-bottom shimmer gradient.
/// Can also be used standalone outside of [SmartScrollView].
class LiquidGlassAppBar extends StatelessWidget {
  /// Height of the device status bar — use `MediaQuery.of(context).padding.top`.
  final double statusBarHeight;

  /// Replaces the default back button. Use [SmartScrollIconButton] for
  /// consistent styling.
  final Widget? leading;

  /// Widget placed on the right side of the app bar.
  final Widget? trailing;

  /// Page title displayed in the centre.
  final String? title;

  /// Called when the default back button is pressed.
  /// Defaults to `Navigator.pop(context)`.
  final VoidCallback? onBackPressed;

  /// Whether to show a default back button when [leading] is null.
  /// Set to `false` to show nothing on the left side. Defaults to `true`.
  final bool automaticallyImplyLeading;

  /// Background colour blended into the glass layer.
  /// Defaults to `Colors.white` at low opacity.
  final Color? glassColor;

  /// Blur intensity. Lower values let more background show through.
  final double blurSigma;

  const LiquidGlassAppBar({
    super.key,
    required this.statusBarHeight,
    this.leading,
    this.trailing,
    this.title,
    this.onBackPressed,
    this.glassColor,
    this.blurSigma = 54.0,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final base = glassColor ?? Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          height: statusBarHeight + 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: 0.55),
                base.withValues(alpha: 0.38),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: base.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content row
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      leading ??
                          (automaticallyImplyLeading
                              ? SmartScrollIconButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  onPressed: onBackPressed ??
                                      () => Navigator.maybePop(context),
                                )
                              : const SizedBox(width: 46)),
                      Expanded(
                        child: Text(
                          title ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      trailing ?? const SizedBox(width: 46),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small circular glass-style icon button.
///
/// Use in [LiquidGlassAppBar]'s `leading` or `trailing` slots for
/// consistent look and feel.
///
/// ### Example
/// ```dart
/// SmartScrollView(
///   trailing: SmartScrollIconButton(
///     icon: Icons.share_outlined,
///     onPressed: () => share(),
///   ),
/// )
/// ```
class SmartScrollIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const SmartScrollIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.055),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF222222)),
      ),
    );
  }
}
