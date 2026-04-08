import 'package:flutter/material.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/features/home/presentation/pages/dashboard_page.dart';
import 'package:monitoring_jamur/features/history/presentation/pages/history_page.dart';
import 'package:monitoring_jamur/features/account/presentation/pages/account_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const DashboardPage(),
    const HistoryPage(),
    const AccountPage(),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildAnimatedBottomBar(),
    );
  }

  Widget _buildAnimatedBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double totalWidth = constraints.maxWidth;
          double itemWidth = totalWidth / 3;
          
          return Stack(
            children: [
              // Animated Background Bubble
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                left: _currentIndex * itemWidth + (itemWidth * 0.15),
                top: 12,
                child: Container(
                  width: itemWidth * 0.7,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(23),
                  ),
                ),
              ),
              // Navigation Items
              Row(
                children: [
                  _buildNavItem(0, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home'),
                  _buildNavItem(1, Icons.history_rounded, Icons.history_rounded, 'History'),
                  _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    bool isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textLight.withOpacity(0.6),
                  size: 26,
                ),
              ),
            ),
            if (isSelected) 
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
