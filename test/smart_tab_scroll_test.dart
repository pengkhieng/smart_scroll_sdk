import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tab_scroll/smart_tab_scroll.dart';

void main() {
  // ── SectionConfig ──────────────────────────────────────────
  group('SectionConfig', () {
    test('defaults showInTab to true', () {
      final section = SectionConfig(
        id: 'test',
        title: 'Test',
        builder: (context) => const SizedBox(),
      );
      expect(section.showInTab, isTrue);
      expect(section.hasDataCheck, isNull);
    });

    test('accepts showInTab:false', () {
      final section = SectionConfig(
        id: 'hero',
        title: 'Hero',
        showInTab: false,
        builder: (context) => const SizedBox(),
      );
      expect(section.showInTab, isFalse);
    });
  });

  // ── SmartScrollController ──────────────────────────────────
  group('SmartScrollController', () {
    late SmartScrollController controller;

    setUp(() {
      controller = SmartScrollController(
        sections: [
          SectionConfig(
            id: 'hero',
            title: 'Hero',
            showInTab: false,
            builder: (context) => const SizedBox(),
          ),
          SectionConfig(
            id: 'general',
            title: 'General',
            showInTab: true,
            builder: (context) => const SizedBox(),
          ),
          SectionConfig(
            id: 'payment',
            title: 'Payment',
            showInTab: true,
            hasDataCheck: () async => true,
            builder: (context) => const SizedBox(),
          ),
          SectionConfig(
            id: 'hidden',
            title: 'Hidden',
            showInTab: true,
            hasDataCheck: () async => false,
            builder: (context) => const SizedBox(),
          ),
        ],
      );
    });

    tearDown(() => controller.dispose());

    test('creates a GlobalKey for every section', () {
      expect(controller.sectionKeys.keys,
          containsAll(['hero', 'general', 'payment', 'hidden']));
    });

    test('updateTabSections: adds sections without hasDataCheck immediately',
        () async {
      await controller.updateTabSections();
      expect(controller.tabSectionIds, contains('general'));
    });

    test('updateTabSections: excludes showInTab:false sections', () async {
      await controller.updateTabSections();
      expect(controller.tabSectionIds, isNot(contains('hero')));
    });

    test(
        'updateTabSections: excludes sections where hasDataCheck returns false',
        () async {
      await controller.updateTabSections();
      expect(controller.tabSectionIds, isNot(contains('hidden')));
    });

    test(
        'updateTabSections: includes sections where hasDataCheck returns true',
        () async {
      await controller.updateTabSections();
      expect(controller.tabSectionIds, contains('payment'));
    });

    test('updateTabSections: preserves declaration order', () async {
      await controller.updateTabSections();
      final ids = controller.tabSectionIds;
      final generalIdx = ids.indexOf('general');
      final paymentIdx = ids.indexOf('payment');
      expect(generalIdx, lessThan(paymentIdx));
    });

    test('getSectionTitle returns correct title', () {
      expect(controller.getSectionTitle('general'), 'General');
    });

    test('isValidTabSection returns false before updateTabSections', () {
      expect(controller.isValidTabSection('general'), isFalse);
    });

    test('isValidTabSection returns true after updateTabSections', () async {
      await controller.updateTabSections();
      expect(controller.isValidTabSection('general'), isTrue);
    });

    test('hasReachedSection returns false when position unknown', () {
      expect(controller.hasReachedSection('general', 500), isFalse);
    });
  });
}
