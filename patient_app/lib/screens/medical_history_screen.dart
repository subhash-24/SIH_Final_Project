import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Review'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlowProgressIndicator(
                currentStep: 3,
                totalSteps: 6,
                stepLabel: 'Review',
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Extracted Findings', style: AppTextStyles.subheading),
              const SizedBox(height: AppSpacing.md),
              const SourceBadge(source: 'ai_extracted'),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    _buildFindingCard('Chief Complaint', 'Headache for 3 days'),
                    _buildFindingCard('Associated Symptoms', 'Mild fever'),
                    _buildFindingCard('Negatives', 'No nausea'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Confirm and Continue',
                onPressed: () {
                  context.go('/documents');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFindingCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
