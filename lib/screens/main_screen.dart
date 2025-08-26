import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/colors.dart';
import 'calculator_screen.dart';
import 'challenges_screen.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'discussions_screen.dart';
import 'profile_screen.dart';
import '../widgets/tutorial_overlay.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  final List<Widget> _screens = [
    const CalculatorScreen(),
    const ChallengesScreen(),
    const AchievementsScreen(),
    const LeaderboardScreen(),
    const DiscussionsScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.calculator),
      activeIcon: FaIcon(FontAwesomeIcons.calculator),
      label: 'Calculator',
    ),
    const BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.trophy),
      activeIcon: FaIcon(FontAwesomeIcons.trophy),
      label: 'Challenges',
    ),
    const BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.medal),
      activeIcon: FaIcon(FontAwesomeIcons.medal),
      label: 'Achievements',
    ),
    const BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.rankingStar),
      activeIcon: FaIcon(FontAwesomeIcons.rankingStar),
      label: 'Leaderboard',
    ),
    const BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.comments),
      activeIcon: FaIcon(FontAwesomeIcons.comments),
      label: 'Discussions',
    ),
    const BottomNavigationBarItem(
      icon: FaIcon(FontAwesomeIcons.user),
      activeIcon: FaIcon(FontAwesomeIcons.user),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize user data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      await provider.initializeUser('default_user');

      // Show tutorial if first time user
      if (provider.isFirstTimeUser && !provider.tutorialCompleted) {
        _showTutorial();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TutorialOverlay(),
    );
  }

  void _onTabTapped(int index) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    provider.setCurrentIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: provider.setCurrentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black26,
                ],
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: provider.currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: surface.withOpacity(0.95),
              selectedItemColor: accent,
              unselectedItemColor: textSecondary,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
              ),
              items: _navItems.map((item) {
                int index = _navItems.indexOf(item);
                bool isSelected = provider.currentIndex == index;

                return BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.icon,
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.activeIcon,
                  ),
                  label: item.label,
                );
              }).toList(),
            ),
          ),
          floatingActionButton: provider.currentIndex == 0
              ? FloatingActionButton(
                  onPressed: _showTutorial,
                  backgroundColor: accent,
                  foregroundColor: textOnAccent,
                  child: const FaIcon(FontAwesomeIcons.question),
                )
              : null,
        );
      },
    );
  }
}
