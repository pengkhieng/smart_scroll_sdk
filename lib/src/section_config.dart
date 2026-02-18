import 'package:flutter/material.dart';

/// Configuration for a single scrollable section.
///
/// ### Example
/// ```dart
/// SectionConfig(
///   id: 'payment',
///   title: 'Payment',
///   showInTab: true,
///   hasDataCheck: () async {
///     final data = await PaymentApi.get(orderId);
///     return data != null; // tab appears when THIS call resolves
///   },
///   builder: (context) => PaymentSection(orderId: orderId),
/// )
/// ```
class SectionConfig {
  /// Unique identifier used as the tab key and scroll target.
  final String id;

  /// Label shown in the tab bar.
  final String title;

  /// Whether this section should appear as a tab. Defaults to `true`.
  final bool showInTab;

  /// Builds the section's content widget.
  final WidgetBuilder builder;

  /// Optional async check — return `true` to show the tab, `false` to hide it.
  ///
  /// - If `null` and [showInTab] is `true`, the tab is always shown immediately.
  /// - All [hasDataCheck] calls across all sections are fired **in parallel**.
  ///   Each tab appears the moment its own future resolves, without
  ///   waiting for other sections.
  final Future<bool> Function()? hasDataCheck;

  /// Internally cached rendered height — managed by [SmartScrollController].
  double? cachedHeight;

  SectionConfig({
    required this.id,
    required this.title,
    required this.builder,
    this.showInTab = true,
    this.hasDataCheck,
    this.cachedHeight,
  });
}
