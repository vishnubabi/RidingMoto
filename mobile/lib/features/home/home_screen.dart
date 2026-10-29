import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/routes.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 56),

                    // App icon + title
                    _buildHeader()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.1, end: 0),

                    const SizedBox(height: 48),

                    // Illustration card
                    _buildIllustration()
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                    const Spacer(),

                    // Buttons
                    _buildCreateButton(context)
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 12),

                    _buildJoinButton(context)
                        .animate(delay: 500.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('📍', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'RidingMoto',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Stay connected with your crew\non every journey.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Dots representing riders on map
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(const Color(0xFF4F6FFF)),
              const SizedBox(width: 24),
              _dot(const Color(0xFFFF6B35)),
              const SizedBox(width: 24),
              _dot(const Color(0xFF00C07F)),
              const SizedBox(width: 24),
              _dot(const Color(0xFFFFD600)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'See where everyone is\nin real time',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.createTrip),
      child: const Text('Create a Trip'),
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.pushNamed(context, AppRoutes.joinTrip),
      child: const Text('Join a Trip'),
    );
  }
}
