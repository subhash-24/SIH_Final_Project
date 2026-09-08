import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlowProgressIndicator(
                currentStep: 6,
                totalSteps: 6,
                stepLabel: 'Finish',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Ready to submit', style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Please review your information before submitting it to the doctor.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chief Complaint', style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      Text('Headache for 3 days', style: AppTextStyles.body),
                      const Divider(height: 32),
                      Text('Documents', style: AppTextStyles.label),
                      const SizedBox(height: 4),
                      Text('None uploaded', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Submit to Doctor',
                onPressed: () {
                  context.go('/success');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
