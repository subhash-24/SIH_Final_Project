import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 08 — Past Medical History & Chronic Conditions
/// Touch-first multi-select condition tiles, medication & allergy checklist
class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  static const _conditions = [
    ('Hypertension', 'उच्च रक्तचाप (High BP)', Icons.favorite_outline),
    ('Type 2 Diabetes', 'मधुमेह (Sugar)', Icons.water_drop_outlined),
    ('Coronary Artery Disease', 'हृदय रोग (Heart Disease)', Icons.monitor_heart_outlined),
    ('Asthma / COPD', 'दमा / सांस की बीमारी', Icons.air_outlined),
    ('Thyroid Disorder', 'थायराइड की समस्या', Icons.biotech_outlined),
    ('Chronic Kidney Disease', 'गुर्दे / किडनी की बीमारी', Icons.shield_outlined),
  ];

  String _selectedMedication = 'Regular BP / Diabetes Medications';
  String _selectedAllergy = 'No known drug allergies (NKDA)';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/transcript'),
        ),
        title: Text(state.tr('Past Medical History', 'पिछला चिकित्सा इतिहास')),
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
                        const FlowProgressIndicator(
                          currentStep: 7,
                          totalSteps: 7,
                          stepLabel: 'Medical History • पूर्व इतिहास',
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          state.tr('Chronic Conditions & Medical History', 'पुरानी बीमारियां और पिछला इतिहास'),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Select any long-term health conditions you have been diagnosed with.',
                            'यदि आपको पहले से कोई पुरानी बीमारी या समस्या है, तो कृपया उसे चुनें।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Condition Tiles Grid (2x3 on tablet)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                          itemCount: _conditions.length,
                          itemBuilder: (ctx, i) {
                            final (enName, hiName, icon) = _conditions[i];
                            final isSelected = state.pastConditions.contains(enName);
                            return InkWell(
                              onTap: () => state.togglePastCondition(enName),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      icon,
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            enName,
                                            style: AppTextStyles.labelMedium.copyWith(
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            hiName,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Current Medications Section
                        Text(
                          state.tr('Current Daily Medications / वर्तमान दवाएं', 'वर्तमान दवाएं'),
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Regular BP / Diabetes Medications',
                            'Blood Thinners / Aspirin',
                            'Inhalers / Respiratory Meds',
                            'No regular daily medications',
                          ].map((med) {
                            final isSel = _selectedMedication == med;
                            return ChoiceChip(
                              label: Text(med),
                              selected: isSel,
                              onSelected: (_) => setState(() => _selectedMedication = med),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                              ),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: isSel ? AppColors.primary : AppColors.border,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Drug Allergies Section
                        Text(
                          state.tr('Known Drug Allergies / दवाओं से एलर्जी', 'दवाओं से एलर्जी'),
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'No known drug allergies (NKDA)',
                            'Penicillin Allergy',
                            'Sulfa Drug Allergy',
                            'NSAID / Painkiller Reaction',
                          ].map((alg) {
                            final isSel = _selectedAllergy == alg;
                            return ChoiceChip(
                              label: Text(alg),
                              selected: isSel,
                              onSelected: (_) => setState(() => _selectedAllergy = alg),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                              ),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: isSel ? AppColors.primary : AppColors.border,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'Save History & Continue • आगे बढ़ें',
                            'इतिहास सहेजें और आगे बढ़ें',
                          ),
                          icon: Icons.arrow_forward,
                          onPressed: () => context.go('/documents'),
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
}
