import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:petani_maju/logic/app_lifecycle/app_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "onboarding.page1_title".tr(),
      description: "onboarding.page1_desc".tr(),
      imagePath: 'assets/images/onboarding_welcome.png',
    ),
    OnboardingContent(
      title: "onboarding.page2_title".tr(),
      description: "onboarding.page2_desc".tr(),
      imagePath: 'assets/images/onboarding_weather.png',
    ),
    OnboardingContent(
      title: "onboarding.page3_title".tr(),
      description: "onboarding.page3_desc".tr(),
      imagePath: 'assets/images/onboarding_pests.png',
    ),
    OnboardingContent(
      title: "onboarding.page4_title".tr(),
      description: "onboarding.page4_desc".tr(),
      imagePath: 'assets/images/onboarding_calendar.png',
    ),
    OnboardingContent(
      title: "onboarding.page5_title".tr(),
      description: "onboarding.page5_desc".tr(),
      imagePath: 'assets/images/onboarding_tips.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _contents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(content: _contents[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _contents.length - 1) {
                          context.read<AppBloc>().add(CompleteOnboarding());
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _contents.length - 1
                            ? "onboarding.start".tr()
                            : "onboarding.next".tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage != _contents.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.read<AppBloc>().add(CompleteOnboarding());
                      },
                      child: Text(
                        "onboarding.skip".tr(),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const OnboardingPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            content.imagePath,
            height: 250,
          ),
          const SizedBox(height: 48),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}
