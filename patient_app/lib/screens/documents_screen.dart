import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const FlowProgressIndicator(
                currentStep: 4,
                totalSteps: 6,
                stepLabel: 'Documents',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Any previous reports or prescriptions?',
                style: AppTextStyles.question,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You can skip this if you don\'t have any.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Take Photo',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Upload File',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  context.go('/ayush');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
