import 'package:flutter/material.dart';
import 'section_config.dart';

/// Manages scroll position tracking, section measurement, and tab visibility.
///
/// ### Usage
/// ```dart
/// final controller = SmartScrollController(sections: [...]);
///
/// @override
/// void dispose() {
///   controller.dispose(); // always dispose
///   super.dispose();
/// }
/// ```
class SmartScrollController {
  /// Ordered list of all sections (both tab and non-tab).
  final List<SectionConfig> sections;

  /// GlobalKeys used to measure each section's rendered position and height.
  final Map<String, GlobalKey> sectionKeys = {};

  /// The underlying Flutter scroll controller — attached to [SmartScrollView].
  final ScrollController scrollController = ScrollController();

  /// Whether the tab bar is currently visible.
  bool showTabBar = false;

  /// The currently active section id, or `'__scroll_to_top__'` for Overview.
  String activeSection = '';

  /// Height of the device status bar — set automatically by [SmartScrollView].
  double statusBarHeight = 0.0;

  List<String> _cachedTabSectionIds = [];
  final Map<String, double> _sectionPositions = {};
  final Map<String, double> _sectionHeights = {};
  double _totalContentHeight = 0.0;
  bool _isMeasuring = false;

  SmartScrollController({required this.sections}) {
    for (final section in sections) {
      sectionKeys[section.id] = GlobalKey();
    }
  }

  /// Releases the scroll controller. Call from your `State.dispose()`.
  void dispose() {
    scrollController.dispose();
  }

  // ── Public read API ─────────────────────────────────────────

  /// All sections in declaration order.
  List<SectionConfig> get visibleSections => sections;

  /// Section IDs that are currently shown as tabs (resolved + ordered).
  List<String> get tabSectionIds => _cachedTabSectionIds;

  /// Whether at least one tab section is ready.
  bool get hasAnyTabSections => _cachedTabSectionIds.isNotEmpty;

  /// Total measured content height in logical pixels.
  double get totalContentHeight => _totalContentHeight;

  /// Internal measuring flag — used by [SmartScrollView] to avoid re-entrancy.
  bool get isMeasuring => _isMeasuring;

  /// Rendered top offset of a section, or `null` if not yet measured.
  double? getSectionPosition(String id) => _sectionPositions[id];

  /// Rendered height of a section, or `null` if not yet measured.
  double? getSectionHeight(String id) => _sectionHeights[id];

  /// Whether [sectionId] is in the tab list.
  bool isValidTabSection(String sectionId) =>
      _cachedTabSectionIds.contains(sectionId);

  /// Returns the display title for a given section id.
  String getSectionTitle(String sectionId) {
    return sections
        .firstWhere(
          (s) => s.id == sectionId,
          orElse: () => SectionConfig(
            id: sectionId,
            title: sectionId,
            builder: (context) => const SizedBox(),
          ),
        )
        .title;
  }

  /// Returns `true` once scroll has reached [threshold] px above [sectionId].
  bool hasReachedSection(String sectionId, double scrollOffset,
      {double threshold = 20}) {
    final position = _sectionPositions[sectionId];
    if (position == null) return false;
    return scrollOffset >= position - threshold;
  }

  // ── Section measurement ─────────────────────────────────────

  /// Walks each section's [GlobalKey] and records its rendered height and
  /// cumulative top offset. Called on every scroll event and after each
  /// tab resolves.
  void measureSections(BuildContext context) {
    if (_isMeasuring) return;
    _isMeasuring = true;
    try {
      double currentPosition = 0;
      _sectionPositions.clear();
      _sectionHeights.clear();
      for (final section in sections) {
        final ctx = sectionKeys[section.id]?.currentContext;
        if (ctx != null) {
          final box = ctx.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            _sectionPositions[section.id] = currentPosition;
            _sectionHeights[section.id] = box.size.height;
            section.cachedHeight = box.size.height;
            currentPosition += box.size.height;
          }
        }
      }
      _totalContentHeight = currentPosition;
    } finally {
      _isMeasuring = false;
    }
  }

  // ── Tab resolution ──────────────────────────────────────────

  /// Inserts [sectionId] into [_cachedTabSectionIds] while preserving
  /// the original [sections] declaration order, regardless of which
  /// future resolved first.
  void _insertInOrder(String sectionId) {
    if (_cachedTabSectionIds.contains(sectionId)) return;
    final targetIdx = sections.indexWhere((s) => s.id == sectionId);
    int insertAt = _cachedTabSectionIds.length;
    for (int i = 0; i < _cachedTabSectionIds.length; i++) {
      final existingIdx =
          sections.indexWhere((s) => s.id == _cachedTabSectionIds[i]);
      if (existingIdx > targetIdx) {
        insertAt = i;
        break;
      }
    }
    _cachedTabSectionIds.insert(insertAt, sectionId);
  }

  /// Resolves which sections appear as tabs.
  ///
  /// - Sections **without** [SectionConfig.hasDataCheck] → added synchronously.
  /// - Sections **with** [SectionConfig.hasDataCheck] → fired **in parallel**.
  ///   [onSectionAdded] fires each time a single check resolves so the UI
  ///   can call `setState` right away — no waiting for all calls to finish.
  Future<void> updateTabSections({void Function()? onSectionAdded}) async {
    _cachedTabSectionIds.clear();
    final futures = <Future<void>>[];

    for (final section in sections) {
      if (!section.showInTab) continue;

      if (section.hasDataCheck == null) {
        _insertInOrder(section.id);
        onSectionAdded?.call();
      } else {
        futures.add(
          section.hasDataCheck!().then((hasData) {
            if (hasData) {
              _insertInOrder(section.id);
              onSectionAdded?.call();
            }
          })
          // Intentionally swallow errors — a failing hasDataCheck simply
          // keeps the tab hidden rather than crashing the entire screen.
          .catchError((_) {}),
        );
      }
    }

    await Future.wait(futures);
  }
}
