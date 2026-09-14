import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 11 — Patient Intake Summary
/// Clean structured clinical summary with provenance chips and one-touch submission
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final (primaryPrakriti, _) = state.calculatePrakritiBaseline();

    final patient = state.patient;
    final findings = state.findings;
    final pastConditions = state.pastConditions.toList();
    final hasRedFlags = state.hasUrgentRedFlag;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/ayush'),
        ),
        title: Text(state.tr('Intake Summary', 'पंजीकरण सारांश')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.tr('Ready for Physician Review', 'चिकित्सक समीक्षा के लिए तैयार'),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Please review your structured case summary below before submitting it to the doctor’s queue.',
                            'डॉक्टर की कतार में भेजने से पहले कृपया नीचे अपने मामले का संक्षिप्त विवरण जांच लें।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Important Alert Banner if present
                        if (hasRedFlags) ...[
                          const RestrainedAlertBanner(
                            title: 'Urgent Clinical Review Required',
                            message: 'Chest discomfort pattern flagged for prioritized physician assessment.',
                            criteria: ['Chest Pain', 'Radiation to left arm', 'Sweating'],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Section 1: Patient Demographics
                        _buildSectionHeader(
                          state.tr('1. Patient Information / रोगी विवरण', 'रोगी विवरण'),
                          'ABHA Verified',
                        ),
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    patient.name.isNotEmpty ? patient.name : 'Ramesh Kumar',
                                    style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SourceBadge(source: 'patient_reported'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${patient.age.isNotEmpty ? patient.age : '48'} Yrs • ${patient.gender} • Mob: ${patient.mobile.isNotEmpty ? patient.mobile : '9876543210'}',
                                style: AppTextStyles.bodySmall,
                              ),
                              if (patient.abhaNumber.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ABHA: ${patient.abhaNumber}',
                                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Section 2: Chief Complaint & Present Symptoms
                        _buildSectionHeader(
                          state.tr('2. Presenting Symptoms / मुख्य लक्षण', 'मुख्य लक्षण'),
                          'AI Structured',
                        ),
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (findings.isNotEmpty) ...[
                                ...findings.map((f) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• ${_formatKey(f.fieldType)}: ',
                                          style: AppTextStyles.labelMedium.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            f.value,
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SourceBadge(source: f.source),
                                      ],
                                    ),
                                  );
                                }),
                              ] else ...[
                                const Text(
                                  '• Chief Complaint: Severe chest pain for 2 hours radiating to left arm with sweating.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Section 3: Past History, Medications, Allergies
                        _buildSectionHeader(
                          state.tr('3. Medical History & Medications / पुराना इतिहास', 'पुराना इतिहास'),
                          'Patient Reported',
                        ),
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chronic Conditions: ${pastConditions.isNotEmpty ? pastConditions.join(", ") : "Hypertension (High BP)"}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const Divider(height: 18, color: AppColors.border),
                              Text(
                                'Daily Medications: Regular BP Medications (Tab Telmisartan 40mg)',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Allergies: No known drug allergies (NKDA)',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Section 4: AYUSH Profile
                        _buildSectionHeader(
                          state.tr('4. AYUSH Constitutional Baseline / आयुष तासीर', 'आयुष तासीर'),
                          'Integrative Baseline',
                        ),
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.spa, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Primary Prakriti: $primaryPrakriti',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Questionnaire-based assessment for clinical lifestyle baseline.',
                                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SourceBadge(source: 'patient_reported'),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'Submit to Doctor’s Queue • डॉक्टर को भेजें',
                            'डॉक्टर को भेजें और टोकन लें',
                          ),
                          icon: Icons.send_rounded,
                          onPressed: () => context.go('/success'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String tag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
          Text(
            tag,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    switch (key.toLowerCase()) {
      case 'chief_complaint':
        return 'Chief Complaint';
      case 'duration':
        return 'Duration';
      case 'severity':
        return 'Severity';
      case 'radiation':
        return 'Radiation';
      case 'associated':
        return 'Associated';
      case 'hpi':
        return 'Clinical Summary';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }
}
