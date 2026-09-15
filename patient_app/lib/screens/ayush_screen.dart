import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';
import '../services/api_service.dart';

/// Screen 10 — AYUSH / Prakriti Baseline
/// Matches Stitch Screen 5 standards: Clean clinical questionnaire,
/// prominent non-diagnostic disclaimer, real-time baseline dosha distribution.
class AyushScreen extends StatelessWidget {
  const AyushScreen({super.key});

  static const _questions = [
    {
      'id': 'digestion',
      'title': '1. Digestion & Appetite / पाचन एवं भूख',
      'options': [
        {'label': 'Irregular / Variable (असामान्य)', 'dosha': 'vata', 'desc': 'Appetite fluctuates, gas/bloating tendency'},
        {'label': 'Sharp / Quick (तीव्र भूख)', 'dosha': 'pitta', 'desc': 'Cannot skip meals, strong thirst, hyperacidity tendency'},
        {'label': 'Slow / Steady (धीमी भूख)', 'dosha': 'kapha', 'desc': 'Low appetite, can easily skip meals without discomfort'},
      ],
    },
    {
      'id': 'sleep',
      'title': '2. Sleep Quality / नींद की गुणवत्ता',
      'options': [
        {'label': 'Light & Broken (हल्की नींद)', 'dosha': 'vata', 'desc': 'Wakes up easily, light sleeper, active thoughts'},
        {'label': 'Moderate & Sound (संतुलित नींद)', 'dosha': 'pitta', 'desc': '6–7 hours sound sleep, feels rested'},
        {'label': 'Deep & Heavy (गहरी नींद)', 'dosha': 'kapha', 'desc': 'Heavy sleeper, difficult to awaken in the morning'},
      ],
    },
    {
      'id': 'frame',
      'title': '3. Physical Frame & Build / शारीरिक बनावट',
      'options': [
        {'label': 'Slender / Lean (पतला ढांचा)', 'dosha': 'vata', 'desc': 'Prominent joints, quick movements, difficulty gaining weight'},
        {'label': 'Medium / Athletic (मध्यम ढांचा)', 'dosha': 'pitta', 'desc': 'Moderate muscle tone, balanced frame'},
        {'label': 'Broad / Solid (चौड़ा/मजबूत ढांचा)', 'dosha': 'kapha', 'desc': 'Solid bones, gains weight easily, slow movements'},
      ],
    },
    {
      'id': 'weather',
      'title': '4. Thermal Sensitivity / मौसम अनुकूलता',
      'options': [
        {'label': 'Dislikes Cold & Wind (ठंड बर्दाश्त नहीं)', 'dosha': 'vata', 'desc': 'Hands and feet get cold easily'},
        {'label': 'Dislikes Heat & Sun (गर्मी बर्दाश्त नहीं)', 'dosha': 'pitta', 'desc': 'Sweats easily, prefers cold drinks'},
        {'label': 'Dislikes Damp & Humidity (नमी बर्दाश्त नहीं)', 'dosha': 'kapha', 'desc': 'Discomfort in cold, wet weather'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final (primaryPrakriti, doshaDist) = state.calculatePrakritiBaseline();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/documents'),
        ),
        title: Text(state.tr('AYUSH Baseline', 'आयुष प्रकृति मूल्यांकन')),
        actions: [
          TextButton(
            onPressed: () => context.go('/summary'),
            child: Text(
              state.tr('Skip', 'छोड़ें'),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                          state.tr('AYUSH Prakriti Baseline Profile', 'आयुष प्रकृति प्रोफ़ाइल'),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Standardized questionnaire helping your physician understand your constitutional baseline.',
                            'प्रकृति मूल्यांकन आपके डॉक्टर को आपकी शारीरिक तासीर और जीवनशैली समझने में मदद करता है।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Mandatory Medical Disclaimer Banner (Matching Stitch Screen 5)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.tr(
                                    'Questionnaire-based assessment. Not a medical diagnosis. Used solely as an integrative clinical baseline.',
                                    'यह केवल प्रश्नावली आधारित मूल्यांकन है, कोई चिकित्सीय निदान नहीं। केवल परामर्श संदर्भ के लिए।',
                                  ),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Real-time Calculated Prakriti Tile
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    state.tr('Constitutional Baseline', 'संवैधानिक प्रकृति'),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AYUSH CCRAS Framework',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                primaryPrakriti,
                                style: AppTextStyles.headlineMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Dosha Distribution Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: (doshaDist['Pitta'] ?? 0) > 0 ? doshaDist['Pitta']! : 1,
                                      child: Container(height: 8, color: const Color(0xFFD97706)),
                                    ),
                                    Expanded(
                                      flex: (doshaDist['Vata'] ?? 0) > 0 ? doshaDist['Vata']! : 1,
                                      child: Container(height: 8, color: AppColors.primary),
                                    ),
                                    Expanded(
                                      flex: (doshaDist['Kapha'] ?? 0) > 0 ? doshaDist['Kapha']! : 1,
                                      child: Container(height: 8, color: const Color(0xFF1E6F50)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDoshaLegend('Pitta (पित्त)', '${doshaDist['Pitta'] ?? 0}%', const Color(0xFFD97706)),
                                  _buildDoshaLegend('Vata (वात)', '${doshaDist['Vata'] ?? 0}%', AppColors.primary),
                                  _buildDoshaLegend('Kapha (कफ)', '${doshaDist['Kapha'] ?? 0}%', const Color(0xFF1E6F50)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Questionnaire Cards
                        ..._questions.map((q) {
                          final qId = q['id'] as String;
                          final qTitle = q['title'] as String;
                          final options = q['options'] as List<Map<String, String>>;
                          final selectedDosha = state.prakritiAnswers[qId];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: ClinicalCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    qTitle,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...options.map((opt) {
                                    final optDosha = opt['dosha']!;
                                    final isSelected = selectedDosha != null && selectedDosha == optDosha;

                                    return InkWell(
                                      onTap: () => state.setPrakritiAnswer(qId, optDosha),
                                      borderRadius: BorderRadius.circular(8),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                                  width: 1.5,
                                                ),
                                                color: isSelected ? AppColors.primary : Colors.transparent,
                                              ),
                                              child: isSelected
                                                  ? Center(
                                                      child: Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: const BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    opt['label']!,
                                                    style: AppTextStyles.labelMedium.copyWith(
                                                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    opt['desc']!,
                                                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: AppSpacing.xl),

                        PrimaryButton(
                          label: state.tr(
                            'Save AYUSH Profile & Continue • आगे बढ़ें',
                            'आयुष प्रोफ़ाइल सहेजें और आगे बढ़ें',
                          ),
                          icon: Icons.arrow_forward,
                          onPressed: () {
                            if (state.encounterId != null && state.prakritiAnswers.isNotEmpty) {
                              ApiService.submitPrakriti(
                                encounterId: state.encounterId!,
                                answers: state.prakritiAnswers,
                              ).catchError((_) => <String, dynamic>{});
                            }
                            context.go('/summary');
                          },
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

  Widget _buildDoshaLegend(String name, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          '$name: $pct',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
