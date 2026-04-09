import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            children: [
              _cardWrapper(
                isMobile,
                _statCard(
                  "Revenue",
                  "3 407",
                  Icons.trending_up,
                  Colors.pinkAccent,
                ),
              ),
              if (!isMobile)
                const SizedBox(width: 20)
              else
                const SizedBox(height: 20),
              _cardWrapper(
                isMobile,
                _statCard(
                  "Orders",
                  "5 679",
                  Icons.shopping_cart,
                  Colors.tealAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            height: 250,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _neumorphic(),
            child: Center(
              child: Icon(
                Icons.bar_chart_rounded,
                size: 80,
                color: DefaultColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _cardWrapper(bool isMobile, Widget child) =>
      isMobile ? child : Expanded(child: child);

  Widget _statCard(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _neumorphic(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: c.withValues(alpha: 0.1),
            child: Icon(i, color: c, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                v,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _neumorphic() {
    return BoxDecoration(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(10, 10),
          blurRadius: 20,
        ),
        const BoxShadow(
          color: Colors.white,
          offset: Offset(-10, -10),
          blurRadius: 20,
        ),
      ],
    );
  }
}
