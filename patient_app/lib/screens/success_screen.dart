import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.successBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 64, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Intake Complete!',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your information has been successfully sent to the doctor. Please wait for your name to be called.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              SecondaryButton(
                label: 'Start New Patient (Demo)',
                onPressed: () {
                  context.go('/welcome');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
