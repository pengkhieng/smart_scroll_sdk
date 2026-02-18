# smart_tab_scroll

A Flutter SDK for building smart-scrolling screens with a liquid-glass
app bar and auto-managed tab bar.

Tabs appear **incrementally** as API calls resolve — each tab shows up
independently, in parallel, without waiting for others.

---

## Preview

![Before scroll](https://raw.githubusercontent.com/pengkhieng/smart_scroll_sdk/main/doc/screenshots/one_before_scroll.png)
![General section](https://raw.githubusercontent.com/pengkhieng/smart_scroll_sdk/main/doc/screenshots/two_section_general.png)

![General section](https://raw.githubusercontent.com/pengkhieng/smart_scroll_sdk/main/doc/videos/v_demo.gif)

---

## Installation

```yaml
dependencies:
  smart_tab_scroll: ^0.0.1
```

```dart
import 'package:smart_tab_scroll/smart_tab_scroll.dart';
```

---

## Quick start

```dart
import 'package:smart_tab_scroll/smart_tab_scroll.dart';

class OrderScreen extends StatefulWidget { ... }

class _OrderScreenState extends State<OrderScreen> {
  late final SmartScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SmartScrollController(
      sections: [
        SectionConfig(
          id: 'hero',
          title: 'Hero',
          showInTab: false,
          builder: (context) => HeroWidget(),
        ),
        SectionConfig(
          id: 'general',
          title: 'General',
          showInTab: true,
          hasDataCheck: () async {
            final data = await GeneralApi.get();
            return data != null;
          },
          builder: (context) => GeneralWidget(),
        ),
        SectionConfig(
          id: 'payment',
          title: 'Payment',
          showInTab: true,
          hasDataCheck: () async {
            final data = await PaymentApi.get();
            return data != null;
          },
          builder: (context) => PaymentWidget(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmartScrollView(
      controller: _controller,
      title: 'Order Details',
      activeTabIndicatorColor: Colors.green,
      appBarGlassColor: const Color(0xFFF5F2ED),
      tabBarGlassColor: const Color(0xFFF5F2ED),
      appBarBlurSigma: 30,
      tabBarBlurSigma: 10,
      onBackPressed: () => Navigator.pop(context),
      trailing: SmartScrollIconButton(
        icon: Icons.share_outlined,
        onPressed: () => share(),
      ),
    );
  }
}
```

---

## SectionConfig

| Property       | Type                      | Default | Description                                      |
|----------------|---------------------------|---------|--------------------------------------------------|
| `id`           | `String`                  | —       | Unique key, used as scroll target                |
| `title`        | `String`                  | —       | Label shown in the tab bar                       |
| `builder`      | `WidgetBuilder`           | —       | Builds the section content                       |
| `showInTab`    | `bool`                    | `true`  | Whether to show as a tab                         |
| `hasDataCheck` | `Future<bool> Function()` | `null`  | Async check — tab shown only when returns `true` |

---

## SmartScrollView

| Property            | Type                    | Default             | Description                                        |
|---------------------|-------------------------|---------------------|----------------------------------------------------|
| `controller`        | `SmartScrollController` | required            | Create in `initState`                              |
| `title`             | `String?`               | `null`              | App bar title                                      |
| `leading`           | `Widget?`               | Back button         | Left side of app bar                               |
| `trailing`          | `Widget?`               | Empty space         | Right side of app bar                              |
| `onBackPressed`     | `VoidCallback?`         | `Navigator.pop`     | Back button handler                                |
| `topDescription`    | `Widget?`               | `null`              | Widget above first section                         |
| `activeTabIndicatorColor` | `Color`            | `Colors.black`      | Active tab indicator and label colour              |
| `tabBarActiveColorTextColor` | `Color`         | `Colors.black`      | Active tab text colour                             |
| `appBarGlassColor`  | `Color?`                | `Colors.white`      | Tint colour for the app bar glass blur             |
| `tabBarGlassColor`  | `Color?`                | `Colors.white`      | Tint colour for the tab bar glass blur             |
| `appBarBlurSigma`   | `double`                | `54.0`              | App bar blur intensity (lower = more transparent)  |
| `tabBarBlurSigma`   | `double`                | `54.0`              | Tab bar blur intensity (lower = more transparent)  |

---

## How tabs appear

| Section setup                              | Behaviour                                          |
|--------------------------------------------|----------------------------------------------------|
| `showInTab: false`                         | Scrolls normally, never shows as a tab             |
| `showInTab: true`, no `hasDataCheck`       | Tab added immediately on first render              |
| `showInTab: true`, `hasDataCheck` → `true` | Tab added the moment its future resolves           |
| `showInTab: true`, `hasDataCheck` → `false`| Tab never shown                                    |

All `hasDataCheck` calls fire **in parallel**. Tab order always matches
the `sections` declaration order regardless of which future resolved first.

---

## Detail screen pattern — tabs that depend on a main API call

A common use case is a **detail screen** where:

1. The screen opens and immediately calls a main API to fetch the detail data (showing a shimmer while it loads).
2. Sub-sections (Delivery, Payment, etc.) need data **from that response** before they can make their own API calls.

Use a `Completer` in your screen state to coordinate this without blocking the UI.

```dart
class _OrderScreenState extends State<OrderScreen> {
  late final SmartScrollController _controller;

  // Completes with the detail data once the main API call succeeds.
  final Completer<OrderDetail> _detailCompleter = Completer();
  OrderDetail? _detail;

  @override
  void initState() {
    super.initState();

    _controller = SmartScrollController(
      sections: [
        // 1. Overview — renders immediately with a shimmer, no tab.
        SectionConfig(
          id: 'overview',
          title: 'Overview',
          showInTab: false,
          builder: (context) => _detail == null
              ? const OverviewShimmer()
              : OverviewSection(detail: _detail!),
        ),

        // 2. Delivery — waits for the detail, then uses detail.deliveryId.
        SectionConfig(
          id: 'delivery',
          title: 'Delivery',
          showInTab: true,
          hasDataCheck: () async {
            final detail = await _detailCompleter.future; // waits for overview
            final delivery = await DeliveryApi.get(detail.deliveryId);
            return delivery != null;
          },
          builder: (context) => DeliverySection(detail: _detail!),
        ),

        // 3. Payment — same pattern, runs in parallel with Delivery.
        SectionConfig(
          id: 'payment',
          title: 'Payment',
          showInTab: true,
          hasDataCheck: () async {
            final detail = await _detailCompleter.future;
            final payment = await PaymentApi.get(detail.paymentId);
            return payment != null;
          },
          builder: (context) => PaymentSection(detail: _detail!),
        ),
      ],
    );

    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await DetailApi.get(widget.orderId);
      setState(() => _detail = detail); // overview rebuilds with real data
      _detailCompleter.complete(detail); // unblocks delivery + payment
    } catch (e) {
      _detailCompleter.completeError(e); // delivery + payment tabs stay hidden
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Load sequence

```
Screen opens
  ├── overview section → shows shimmer
  ├── delivery hasDataCheck → waiting for _detailCompleter...
  └── payment hasDataCheck  → waiting for _detailCompleter...

DetailApi.get() finishes
  ├── setState() → overview rebuilds with real data (shimmer gone)
  └── _detailCompleter.complete(detail)
        ├── delivery hasDataCheck runs → DeliveryApi.get(detail.deliveryId)
        └── payment hasDataCheck runs  → PaymentApi.get(detail.paymentId)
              ↓ both run in parallel
        Each tab slides in the moment its own check resolves.
```

### Error behaviour

| What fails | Result |
|------------|--------|
| Main detail API fails | `completeError` → all dependent `hasDataCheck` throw → tabs stay hidden |
| `DeliveryApi` returns `null` | Delivery tab hidden, Payment tab unaffected |
| `PaymentApi` throws | Payment tab hidden, Delivery tab unaffected |

> **Rule:** Always call either `_detailCompleter.complete()` or
> `_detailCompleter.completeError()` in every code path of `_loadDetail`.
> If neither is called, the dependent `hasDataCheck` futures never resolve
> and their tabs never appear.

---

## Running the example

```bash
cd example
flutter pub get
flutter run
```

---

## License

MIT
# smart_scroll_sdk
