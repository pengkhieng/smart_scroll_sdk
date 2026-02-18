import 'package:flutter/material.dart';
import '../smart_scroll_controller.dart';
import 'liquid_glass_app_bar.dart';
import 'liquid_glass_tab_bar.dart';

/// The main SDK widget.
///
/// Provides a scrollable screen with:
/// - A frosted-glass app bar (always visible)
/// - A frosted-glass tab bar (appears once the user reaches the first tab section)
/// - Automatic section measurement and active-tab tracking
///
/// ### Minimal usage
/// ```dart
/// class OrderScreen extends StatefulWidget { ... }
///
/// class _OrderScreenState extends State<OrderScreen> {
///   late final SmartScrollController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = SmartScrollController(sections: [
///       SectionConfig(
///         id: 'general',
///         title: 'General',
///         showInTab: true,
///         hasDataCheck: () async => await GeneralApi.hasData(),
///         builder: (context) => GeneralSection(),
///       ),
///     ]);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return SmartScrollView(
///       controller: _controller,
///       title: 'Order Details',
///     );
///   }
/// }
/// ```
class SmartScrollView extends StatefulWidget {
  /// Required. Created in `initState`, disposed in `dispose`.
  final SmartScrollController controller;

  /// Page title shown centred in the app bar.
  final String? title;

  /// Replaces the default back button. Use [SmartScrollIconButton].
  final Widget? leading;

  /// Widget placed on the right side of the app bar. Use [SmartScrollIconButton].
  final Widget? trailing;

  /// Called when the back button is pressed.
  /// Defaults to `Navigator.pop(context)`.
  final VoidCallback? onBackPressed;

  /// Whether to show a default back button when [leading] is null.
  /// Set to `false` to show nothing on the left side. Defaults to `true`.
  final bool automaticallyImplyLeading;

  /// Optional widget rendered above all sections.
  final Widget? topDescription;

  /// Colour used for the active tab indicator and label. Defaults to `Colors.black`.
  final Color activeTabIndicatorColor;

  /// Text colour for the active tab label. Defaults to `Colors.black`.
  final Color tabBarActiveColorTextColor;

  /// Font weight for tab labels. Defaults to [FontWeight.w600].
  final FontWeight tabBarSectionsFontWeight;

  /// Background colour blended into the app bar glass layer.
  /// Defaults to `Colors.white`.
  final Color? appBarGlassColor;

  /// Background colour blended into the tab bar glass layer.
  /// Defaults to `Colors.white`.
  final Color? tabBarGlassColor;

  /// Blur intensity for the app bar glass effect.
  /// Lower values let more background content show through.
  /// Defaults to `54.0`.
  final double appBarBlurSigma;

  /// Blur intensity for the tab bar glass effect.
  /// Lower values let more background content show through.
  /// Defaults to `54.0`.
  final double tabBarBlurSigma;

  /// Whether to show the Overview tab in the tab bar. Defaults to `true`.
  final bool showOverviewTab;

  /// Label for the Overview tab. Defaults to `'Overview'`.
  final String overviewTabLabel;

  const SmartScrollView({
    super.key,
    required this.controller,
    this.title,
    this.leading,
    this.trailing,
    this.onBackPressed,
    this.topDescription,
    this.activeTabIndicatorColor = Colors.black,
    this.tabBarActiveColorTextColor = Colors.black,
    this.tabBarSectionsFontWeight = FontWeight.w600,
    this.appBarGlassColor,
    this.tabBarGlassColor,
    this.appBarBlurSigma = 54.0,
    this.tabBarBlurSigma = 54.0,
    this.automaticallyImplyLeading = true,
    this.showOverviewTab = true,
    this.overviewTabLabel = 'Overview',
  });

  @override
  State<SmartScrollView> createState() => _SmartScrollViewState();
}

class _SmartScrollViewState extends State<SmartScrollView>
    with SingleTickerProviderStateMixin {
  static const double _appBarHeight = 60.0;
  static const double _tabBarHeight = 58.0;

  bool _isLoadingTabs = true;
  bool _isAnimatingToSection = false;

  late AnimationController _tabBarAnimController;

  @override
  void initState() {
    super.initState();
    _tabBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.controller.scrollController.addListener(_onScroll);
    _loadTabSections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.statusBarHeight = MediaQuery.of(context).padding.top;
  }

  @override
  void didUpdateWidget(SmartScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.scrollController.removeListener(_onScroll);
      widget.controller.scrollController.addListener(_onScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.measureSections(context);
    });
  }

  // ── Tab loading ─────────────────────────────────────────────

  Future<void> _loadTabSections() async {
    // Unlock rendering immediately so sections paint before tabs resolve.
    if (mounted) {
      setState(() {
        _isLoadingTabs = false;
        widget.controller.activeSection = '__scroll_to_top__';
      });
    }

    await widget.controller.updateTabSections(
      onSectionAdded: () {
        if (!mounted) return;
        // Each resolved tab gets its own setState — no waiting for others.
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.controller.measureSections(context);
        });
      },
    );
  }

  // ── Scroll handling ─────────────────────────────────────────

  void _onScroll() {
    if (!mounted) return;
    if (_isAnimatingToSection) return;
    final offset = widget.controller.scrollController.offset;

    if (!widget.controller.hasAnyTabSections) {
      if (widget.controller.showTabBar) {
        setState(() => widget.controller.showTabBar = false);
        _tabBarAnimController.reverse();
      }
      return;
    }

    if (!widget.controller.isMeasuring) {
      widget.controller.measureSections(context);
    }

    // Hide tab bar when scrolled back to top.
    if (offset < 10) {
      if (widget.controller.showTabBar) {
        setState(() {
          widget.controller.showTabBar = false;
          widget.controller.activeSection = '__scroll_to_top__';
        });
        _tabBarAnimController.reverse();
      }
      return;
    }

    // Show tab bar once any tab section enters the viewport.
    bool hasReachedAnyTabSection = false;
    for (final id in widget.controller.tabSectionIds) {
      if (widget.controller.hasReachedSection(id, offset,
          threshold: _tabBarHeight)) {
        hasReachedAnyTabSection = true;
        break;
      }
    }

    if (hasReachedAnyTabSection != widget.controller.showTabBar) {
      setState(() => widget.controller.showTabBar = hasReachedAnyTabSection);
      if (hasReachedAnyTabSection) {
        _tabBarAnimController.forward();
      } else {
        _tabBarAnimController.reverse();
      }
    }

    if (widget.controller.showTabBar) {
      _updateActiveSection(offset);
    }
  }

  void _updateActiveSection(double scrollOffset) {
    if (_isAnimatingToSection) return;
    final tabSections = widget.controller.tabSectionIds;
    if (tabSections.isEmpty) return;

    // At the very bottom — snap to last tab.
    final maxExtent =
        widget.controller.scrollController.position.maxScrollExtent;
    if (scrollOffset >= maxExtent - 100) {
      final lastTab = tabSections.last;
      if (lastTab != widget.controller.activeSection) {
        setState(() => widget.controller.activeSection = lastTab);
      }
      return;
    }

    // Find the section whose top edge is just above the tab bar bottom.
    final viewportTop = scrollOffset + _tabBarHeight;
    String? activeSection;

    for (final section in widget.controller.visibleSections) {
      final pos = widget.controller.getSectionPosition(section.id);
      if (pos == null) continue;
      if (pos <= viewportTop) activeSection = section.id;
      if (pos > viewportTop) break;
    }

    if (activeSection == null) return;

    // Map to a tab section (walk back if current section is non-tab).
    final activeTab = widget.controller.isValidTabSection(activeSection)
        ? activeSection
        : _findParentTabSection(activeSection);

    if (activeTab != null && activeTab != widget.controller.activeSection) {
      setState(() => widget.controller.activeSection = activeTab);
    }
  }

  /// Walks backwards from [sectionId] to find the nearest ancestor tab section.
  String? _findParentTabSection(String sectionId) {
    final tabSections = widget.controller.tabSectionIds;
    if (tabSections.isEmpty) return null;
    final all = widget.controller.visibleSections;
    final idx = all.indexWhere((s) => s.id == sectionId);
    if (idx == -1) return null;
    for (int i = idx - 1; i >= 0; i--) {
      if (widget.controller.isValidTabSection(all[i].id)) return all[i].id;
    }
    return tabSections.first;
  }

  // ── Navigation ──────────────────────────────────────────────

  void _scrollToSection(String sectionId) {
    final pos = widget.controller.getSectionPosition(sectionId);
    if (pos == null) return;

    _isAnimatingToSection = true;
    setState(() => widget.controller.activeSection = sectionId);

    final target = pos - _tabBarHeight;
    final max = widget.controller.scrollController.position.maxScrollExtent;

    widget.controller.scrollController
        .animateTo(
          target.clamp(0.0, max),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        )
        .then((_) => _isAnimatingToSection = false);
  }

  void _scrollToTop() {
    _isAnimatingToSection = true;
    setState(() => widget.controller.activeSection = '__scroll_to_top__');
    widget.controller.scrollController
        .animateTo(
          0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          _isAnimatingToSection = false;
          if (!mounted) return;
          if (widget.controller.showTabBar) {
            setState(() => widget.controller.showTabBar = false);
            _tabBarAnimController.reverse();
          }
        });
  }

  // ── Lifecycle ───────────────────────────────────────────────

  @override
  void dispose() {
    widget.controller.scrollController.removeListener(_onScroll);
    _tabBarAnimController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusBarH = widget.controller.statusBarHeight;
    final topPad = statusBarH + _appBarHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2ED),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Scrollable content ───────────────────────────────
          SingleChildScrollView(
            controller: widget.controller.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topPad),
                if (widget.topDescription != null) widget.topDescription!,
                ...widget.controller.visibleSections.map((section) {
                  return Container(
                    key: widget.controller.sectionKeys[section.id],
                    child: section.builder(context),
                  );
                }),
                const SizedBox(height: 200),
              ],
            ),
          ),

          // ── Fixed header: AppBar + animated TabBar ───────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LiquidGlassAppBar(
                  statusBarHeight: statusBarH,
                  leading: widget.leading,
                  trailing: widget.trailing,
                  title: widget.title,
                  onBackPressed: widget.onBackPressed,
                  glassColor: widget.appBarGlassColor,
                  blurSigma: widget.appBarBlurSigma,
                  automaticallyImplyLeading: widget.automaticallyImplyLeading,
                ),
                // Tab bar slides down from under the app bar (SizeTransition
                // clips height 0→58 anchored at the top edge).
                if (!_isLoadingTabs && widget.controller.hasAnyTabSections)
                  SizeTransition(
                    sizeFactor: _tabBarAnimController,
                    axisAlignment: -1.0,
                    child: LiquidGlassTabBar(
                      activeSection: widget.controller.activeSection,
                      tabSections: widget.controller.tabSectionIds,
                      tabSectionsFontWeight: widget.tabBarSectionsFontWeight,
                      onTap: _scrollToSection,
                      onScrollToTop: _scrollToTop,
                      getTitle: widget.controller.getSectionTitle,
                      activeTabIndicatorColor: widget.activeTabIndicatorColor,
                      activeColorTextColor: widget.tabBarActiveColorTextColor,
                      glassColor: widget.tabBarGlassColor,
                      blurSigma: widget.tabBarBlurSigma,
                      showOverviewTab: widget.showOverviewTab,
                      overviewTabLabel: widget.overviewTabLabel,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
