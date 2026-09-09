import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

class TranscriptScreen extends StatelessWidget {
  const TranscriptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcript'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlowProgressIndicator(
                currentStep: 2,
                totalSteps: 6,
                stepLabel: 'Transcript',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Your Spoken Text', style: AppTextStyles.subheading),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      state.transcript.isNotEmpty 
                          ? state.transcript 
                          : state.tr('No transcript available.', 'कोई ट्रांसक्रिप्ट उपलब्ध नहीं है।'),
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Continue to Medical History',
                onPressed: () {
                  context.go('/medical-history');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
