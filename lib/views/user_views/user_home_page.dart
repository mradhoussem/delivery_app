import 'package:delivery_app/tools/default_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;
  String _username = "Utilisateur";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Expéditeur";
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 900;

    final List<Widget> pages = [
      _buildMainDashboard(),
      const Center(child: Text("Mes Livraisons")),
      const Center(child: Text("Paramètres")),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: DefaultColors.background,
      drawer: isWeb ? null : _buildSidebar(),
      body: Row(
        children: [
          if (isWeb && _isSidebarOpen) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWeb),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isWeb) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: DefaultColors.primary, size: 30),
            onPressed: () {
              if (isWeb) {
                setState(() => _isSidebarOpen = !_isSidebarOpen);
              } else {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
          ),
          const Spacer(),
          const Icon(Icons.notifications_none, color: Colors.grey),
          const SizedBox(width: 20),
          CircleAvatar(
            radius: 18,
            backgroundColor: DefaultColors.primary,
            child: Text(_username[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard() {
    final List<Map<String, dynamic>> cardData = [
      {"title": "Total Expéditions", "val": "1,284", "colors": [const Color(0xFF2193b0), const Color(0xFF6dd5ed)]},
      {"title": "En attente", "val": "12", "colors": [const Color(0xFF8e2de2), const Color(0xFF4a00e0)]},
      {"title": "Livrées", "val": "1,272", "colors": [const Color(0xFF11998e), const Color(0xFF38ef7d)]},
      {"title": "Annulées", "val": "05", "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)]},
      {"title": "Annulées", "val": "05", "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)]},
      {"title": "Annulées", "val": "05", "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)]},
      {"title": "Annulées", "val": "05", "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)]},
      {"title": "Annulées", "val": "05", "colors": [const Color(0xFFf46737), const Color(0xFFffb75e)]},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bonjour, $_username", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Que souhaitez-vous faire aujourd'hui ?", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

          _buildActionCard(),

          const SizedBox(height: 40),

          const Text("Statistiques", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // Wrap avec des cartes plus petites
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: cardData.map((data) => StatCardFlip(
              title: data["title"],
              value: data["val"],
              gradientColors: data["colors"], onTap: () {  },
            )).toList(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.8), offset: const Offset(-6, -6), blurRadius: 12),
          BoxShadow(color: DefaultColors.primary.withValues(alpha: 0.1), offset: const Offset(6, 6), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_shipping_rounded, size: 40, color: DefaultColors.primary),
          const SizedBox(height: 15),
          const Text("Nouvelle Expédition", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Envoyez vos colis en quelques clics.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: DefaultColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text("COMMENCER"),
          )
        ],
      ),
    );
  }

  // Widget de carte réduit
  Widget _buildStatCard({
    required String title,
    required String value,
    required List<Color> gradientColors,
  }) {
    // Détection du mode Mobile (généralement largeur < 600 ou 900 selon tes besoins)
    bool isMobile = MediaQuery.of(context).size.width < 600;

    // Définition des dimensions dynamiques
    double cardWidth = isMobile ? 140 : 180;
    double cardHeight = isMobile ? 90 : 100;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.4),
            offset: const Offset(3, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Cercle en haut à gauche
            Positioned(
              top: -20,
              left: -20,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            // Cercle en bas à droite
            Positioned(
              bottom: -15,
              right: -5,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            // Contenu du texte
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize:12, // Optionnel: ajuster la police aussi
                        fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                      value,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18, // Optionnel: ajuster la police aussi
                          fontWeight: FontWeight.bold
                      )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      height: double.infinity,
      color: DefaultColors.background,
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text("USER PORTAL", style: TextStyle(color: DefaultColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 40),
          _sidebarItem(0, Icons.dashboard_rounded, "Accueil"),
          _sidebarItem(1, Icons.inventory_2_rounded, "Mes Colis"),
          _sidebarItem(2, Icons.settings_rounded, "Paramètres"),
          const Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: DefaultColors.primary.withValues(alpha: 0.5)),
            title: const Text("Déconnexion", style: TextStyle(color: DefaultColors.primary)),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (MediaQuery.of(context).size.width <= 900) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? DefaultColors.primary.withValues(alpha:0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: DefaultColors.primary),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(color: DefaultColors.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class StatCardFlip extends StatefulWidget {
  final String title;
  final String value;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const StatCardFlip({
    super.key,
    required this.title,
    required this.value,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<StatCardFlip> createState() => _StatCardFlipState();
}

class _StatCardFlipState extends State<StatCardFlip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    double cardWidth = isMobile ? 140 : 180;
    double cardHeight = isMobile ? 90 : 100;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 500),
          tween: Tween<double>(
            begin: 0,
            end: _isHovered ? math.pi : 0,
          ),
          builder: (context, double value, child) {
            final isFront = value <= math.pi / 2;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(value),
              child: isFront
                  ? _buildFront(cardWidth, cardHeight, isMobile)
                  : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: _buildBack(cardWidth, cardHeight),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- FRONT ---
  Widget _buildFront(double width, double height, bool isMobile) {
    return Container(
      width: width,
      height: height,
      decoration: _cardDecoration(widget.gradientColors),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            _buildCircle(-20, -20, 40, 0.15),
            _buildCircle(null, null, 30, 0.12, bottom: -15, right: -5),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    child: Text(
                      widget.value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BACK ---
  Widget _buildBack(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            _buildCircle(-10, -10, 25, 0.1),
            const Center(
              child: Text(
                "Plus d'information",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STYLE ---
  BoxDecoration _cardDecoration(List<Color> colors) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.last.withOpacity(0.4),
          offset: const Offset(3, 3),
          blurRadius: 8,
        ),
      ],
    );
  }

  Widget _buildCircle(
      double? top,
      double? left,
      double radius,
      double opacity, {
        double? bottom,
        double? right,
      }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

