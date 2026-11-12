import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _primaryTeal = Color(0xFF0891B2);
  static const _navyText = Color(0xFF0A2540);

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.psychology_alt,
      title: 'Welcome to Mental Health Companion',
      subtitle: 'Your private AI-powered wellness assistant',
      gradientColors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
      darkGradientColors: [Color(0xFF0A1A2A), Color(0xFF0D2137)],
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome,
      title: 'Smart AI Analysis',
      subtitle:
          'On-device emotion detection powered by DistilBERT. Your data never leaves your phone.',
      gradientColors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
      darkGradientColors: [Color(0xFF0D1B2A), Color(0xFF112240)],
    ),
    _OnboardingPageData(
      icon: Icons.health_and_safety,
      title: 'Professional Tools',
      subtitle:
          'PHQ-9, GAD-7 assessments, mood tracking, guided exercises, and daily check-ins to support your mental health journey.',
      gradientColors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      darkGradientColors: [Color(0xFF0A2020), Color(0xFF0D2B2B)],
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch,
      title: "You're All Set!",
      subtitle:
          'Start your journey toward better mental health today.',
      gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      darkGradientColors: [Color(0xFF1A1510), Color(0xFF2A2018)],
    ),
  ];

  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconScaleAnimations;

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _pages.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _iconScaleAnimations = _iconControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    }).toList();

    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconControllers[page].forward(from: 0.0);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  void _skipToEnd() {
    _goToPage(_pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _OnboardingPage(
                data: page,
                isDark: isDark,
                scaleAnimation: _iconScaleAnimations[index],
                isLastPage: index == _pages.length - 1,
                onGetStarted: widget.onComplete,
              );
            },
          ),

          // Skip button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: TextButton(
                onPressed: _skipToEnd,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : _navyText.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 32,
            child: Column(
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _primaryTeal
                            : (isDark
                                ? Colors.white24
                                : _navyText.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Next button (hidden on last page since it has Get Started)
                if (_currentPage < _pages.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final List<Color> darkGradientColors;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.darkGradientColors,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isDark;
  final Animation<double> scaleAnimation;
  final bool isLastPage;
  final VoidCallback onGetStarted;

  static const _primaryTeal = Color(0xFF0891B2);
  static const _navyText = Color(0xFF0A2540);

  const _OnboardingPage({
    required this.data,
    required this.isDark,
    required this.scaleAnimation,
    required this.isLastPage,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors =
        isDark ? data.darkGradientColors : data.gradientColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated icon
              ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.white)
                        .withOpacity(isDark ? 0.1 : 0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryTeal.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    size: 72,
                    color: _primaryTeal,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _navyText,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? Colors.white70
                      : _navyText.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 1),

              // Get Started button on last page
              if (isLastPage) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: _primaryTeal.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Spacer to push content above the bottom controls
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}
