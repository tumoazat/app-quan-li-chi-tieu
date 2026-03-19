import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../data/onboarding_repository.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: '💸',
      title: 'Quản lý chi tiêu thông minh',
      description:
          'Theo dõi thu chi hàng ngày một cách dễ dàng. Biết chính xác tiền của bạn đang đi đâu.',
      color: Color(0xFF4CAF50),
    ),
    _OnboardingData(
      icon: '🤖',
      title: 'AI phân tích tài chính',
      description:
          'Trí tuệ nhân tạo tự động phân loại giao dịch và đưa ra lời khuyên tài chính cá nhân hoá.',
      color: Color(0xFF2196F3),
    ),
    _OnboardingData(
      icon: '📊',
      title: 'Báo cáo chi tiết',
      description:
          'Biểu đồ trực quan và báo cáo PDF chuyên nghiệp giúp bạn nắm rõ tài chính mọi lúc mọi nơi.',
      color: Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingRepository().setOnboardingComplete();
    if (mounted) {
      context.go(AppRouter.login);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final activeColor = _pages[_currentPage].color;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Bỏ qua',
                    style: TextStyle(color: activeColor),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return OnboardingPage(
                    icon: page.icon,
                    title: page.title,
                    description: page.description,
                    color: page.color,
                  );
                },
              ),
            ),

            // Indicator and next button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                children: [
                  PageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    activeColor: activeColor,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: activeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Bắt đầu' : 'Tiếp theo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}

class _OnboardingData {
  final String icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
