import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A frosted-glass tab bar rendered below [LiquidGlassAppBar].
///
/// - Tabs span the **full width** of the screen equally.
/// - Active tab is indicated by a 2.5px bottom border with rounded top corners.
/// - The first tab is always "Overview" — tapping it scrolls back to the top.
/// - Tab order always matches the [SectionConfig] declaration order.
class LiquidGlassTabBar extends StatelessWidget {
  /// Currently highlighted section id, or `'__scroll_to_top__'` for Overview.
  final String activeSection;

  /// Ordered list of section IDs to display as tabs.
  final List<String> tabSections;

  /// Called when a section tab is tapped.
  final void Function(String sectionId) onTap;

  /// Returns the display label for a given section id.
  final String Function(String sectionId) getTitle;

  /// Colour used for the active tab label and bottom indicator.
  final Color activeTabIndicatorColor;

  /// Text colour for the active tab. Defaults to [activeTabIndicatorColor] if not provided.
  final Color activeColorTextColor;

  /// Font weight for tab labels. Defaults to [FontWeight.w600].
  final FontWeight tabSectionsFontWeight;

  /// Called when the Overview (first) tab is tapped.
  final VoidCallback? onScrollToTop;

  /// Whether to show the Overview tab. Defaults to `true`.
  final bool showOverviewTab;

  /// Label for the Overview tab. Defaults to `'Overview'`.
  final String overviewTabLabel;

  /// Background colour blended into the glass layer.
  /// Defaults to `Colors.white` at low opacity.
  final Color? glassColor;

  /// Blur intensity. Lower values let more background show through.
  final double blurSigma;

  const LiquidGlassTabBar({
    super.key,
    required this.activeSection,
    required this.tabSections,
    required this.onTap,
    required this.getTitle,
    this.activeTabIndicatorColor = Colors.black,
    this.activeColorTextColor = Colors.black,
    this.tabSectionsFontWeight = FontWeight.w600,
    this.onScrollToTop,
    this.showOverviewTab = true,
    this.overviewTabLabel = 'Overview',
    this.glassColor,
    this.blurSigma = 54.0,
  });

  List<String> get _allIds =>
      showOverviewTab ? ['__scroll_to_top__', ...tabSections] : tabSections;

  @override
  Widget build(BuildContext context) {
    final base = glassColor ?? Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          height: 58,
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
          child: Row(
            children: _allIds.map((id) {
              final isActive = id == activeSection ||
                  (!showOverviewTab &&
                      activeSection == '__scroll_to_top__' &&
                      tabSections.isNotEmpty &&
                      id == tabSections.first);
              final label =
                  id == '__scroll_to_top__' ? overviewTabLabel : getTitle(id);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (id == '__scroll_to_top__') {
                      onScrollToTop?.call();
                    } else {
                      onTap(id);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Label
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: tabSectionsFontWeight,
                            color: isActive
                                ? activeColorTextColor
                                : Colors.black.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        // Active indicator — 2.5px border, rounded top corners
                        if (isActive)
                          Positioned(
                            bottom: 0,
                            left: 12,
                            right: 12,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: activeTabIndicatorColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
