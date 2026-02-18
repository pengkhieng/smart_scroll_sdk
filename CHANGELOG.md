## 0.0.1

* Initial release.
* `SectionConfig` — model for declaring scrollable sections.
* `SmartScrollController` — manages scroll tracking, section measurement,
  and parallel tab resolution.
* `SmartScrollView` — main SDK widget with liquid-glass app bar and
  auto-managed tab bar.
* `LiquidGlassAppBar` — frosted-glass app bar, usable standalone.
* `LiquidGlassTabBar` — frosted-glass tab bar with full-width tabs and
  rounded-top border indicator.
* Customisable glass effect: `appBarGlassColor`, `tabBarGlassColor`,
  `appBarBlurSigma`, `tabBarBlurSigma`.
* Tabs appear incrementally as `hasDataCheck` futures resolve — each tab
  is independent and does not wait for others.
