import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import 'widgets/onboarding_visuals.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    const OnboardingData(
      title: 'Connect Without Limits',
      description: 'Stay connected with the people and communities that matter to you.',
      visual: OnboardingVisual1(),
    ),
    const OnboardingData(
      title: 'Conversations With Context',
      description: 'Keep your messages, media, files and important moments organized.',
      visual: OnboardingVisual2(),
    ),
    const OnboardingData(
      title: 'Turn Chats Into Capsules',
      description: 'Capture important conversations and turn them into organized Conversation Capsules.',
      visual: OnboardingVisual3(),
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppSizes.durationNormal,
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppSizes.durationNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Mobile-first constraint for desktop/web
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500, // Reasonable mobile width
                  maxHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    // 1. TOP BAR (Fixed height segment)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16,
                        vertical: AppSizes.p8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            text: 'Skip',
                            type: AppButtonType.text,
                            onPressed: _finishOnboarding,
                            width: 80,
                          ),
                        ],
                      ),
                    ),

                    // 2. PAGE CONTENT (Expanded to fill space)
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return _OnboardingPageContent(
                            data: _pages[index],
                          );
                        },
                      ),
                    ),

                    // 3. BOTTOM SECTION (Indicators + Buttons)
                    Container(
                      padding: const EdgeInsets.all(AppSizes.p24),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PageIndicator(
                            count: _pages.length,
                            current: _currentPage,
                          ),
                          Gap.h32,
                          Row(
                            children: [
                              // Back Button
                              Expanded(
                                flex: 1,
                                child: AnimatedOpacity(
                                  duration: AppSizes.durationFast,
                                  opacity: _currentPage > 0 ? 1.0 : 0.0,
                                  child: AppButton(
                                    text: 'Back',
                                    type: AppButtonType.text,
                                    onPressed: _currentPage > 0 ? _previousPage : null,
                                  ),
                                ),
                              ),
                              Gap.w16,
                              // Next / Get Started Button
                              Expanded(
                                flex: 2,
                                child: AppButton(
                                  text: _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  onPressed: _nextPage,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Widget visual;

  const OnboardingData({
    required this.title,
    required this.description,
    required this.visual,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Visual Area - Responsive to space
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.5,
                      minHeight: 150,
                    ),
                    child: data.visual,
                  ),
                  Gap.h32,
                  // Text Area
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Gap.h16,
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                  // Extra padding to ensure content isn't cramped at bottom
                  Gap.h32,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: AppSizes.durationNormal,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 6,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.violetGradient : null,
            color: isActive ? null : AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
