import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';

class AyushScreen extends StatelessWidget {
  const AyushScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AYUSH Assessment'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlowProgressIndicator(
                currentStep: 5,
                totalSteps: 6,
                stepLabel: 'AYUSH',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Prakriti Questionnaire', style: AppTextStyles.subheading),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Please answer a few questions about your body type to help the doctor give you a more personalized treatment.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    _buildQuestion('How is your digestion usually?', ['Irregular', 'Strong/Fast', 'Slow']),
                    _buildQuestion('How is your sleep?', ['Light/Broken', 'Sound/Moderate', 'Deep/Heavy']),
                    _buildQuestion('What is your body frame?', ['Thin', 'Medium', 'Broad']),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Finish Assessment',
                onPressed: () {
                  context.go('/summary');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(String question, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppTextStyles.question.copyWith(fontSize: 20)),
          const SizedBox(height: AppSpacing.md),
          ...options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SecondaryButton(label: opt, onPressed: () {}),
              )),
        ],
      ),
    );
  }
}
