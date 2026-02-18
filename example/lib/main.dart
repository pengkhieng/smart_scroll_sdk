import 'package:flutter/material.dart';
import 'package:smart_tab_scroll/smart_tab_scroll.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OrderScreen(),
    );
  }
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

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
          builder: (context) => Container(
            height: 250,
            color: const Color(0xFFE8E4DF),
            child: const Center(
              child: Text('Hero Section',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        SectionConfig(
          id: 'general',
          title: 'General',
          showInTab: true,
          builder: (context) => _buildSection(
              'General Info', const Color.fromARGB(31, 255, 0, 0)),
        ),
        SectionConfig(
          id: 'description',
          title: 'Description',
          showInTab: false,
          hasDataCheck: () async {
            await Future.delayed(const Duration(milliseconds: 12000));
            return true;
          },
          builder: (context) =>
              _buildSection('Description', const Color.fromARGB(35, 0, 255, 4)),
        ),
        SectionConfig(
          id: 'payment',
          title: 'Payment',
          showInTab: true,
          hasDataCheck: () async {
            await Future.delayed(const Duration(milliseconds: 500));
            return true;
          },
          builder: (context) => _buildSection(
              'Payment Details', const Color.fromARGB(40, 0, 42, 255)),
        ),
        SectionConfig(
          id: 'delivery',
          title: 'Delivery',
          showInTab: true,
          hasDataCheck: () async {
            await Future.delayed(const Duration(seconds: 1));
            return true;
          },
          builder: (context) => _buildSection(
              'Delivery Info', const Color.fromARGB(42, 212, 0, 255)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Color color) {
    return Container(
      color: color,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...List.generate(
            6,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
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
      activeTabIndicatorColor: const Color(0xFF10B981),
      tabBarBlurSigma: 20,
      appBarBlurSigma: 30,
      // appBarGlassColor: const Color.fromARGB(66, 245, 242, 237),
      // tabBarGlassColor: const Color.fromARGB(66, 245, 242, 237),
      onBackPressed: () {
        // Handle back press if needed. Omit this to use the default Navigator.maybePop.
      },
      automaticallyImplyLeading: true,
      // showOverviewTab: false,
    );
  }
}
