import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

class VoiceInterviewScreen extends StatelessWidget {
  const VoiceInterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Interview'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const FlowProgressIndicator(
                currentStep: 1,
                totalSteps: 6,
                stepLabel: 'Interview',
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Please describe your symptoms...',
                style: AppTextStyles.question,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand, width: 2),
                ),
                child: const Icon(Icons.mic, size: 64, color: AppColors.brand),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Finish Recording',
                onPressed: () {
                  context.go('/transcript');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
