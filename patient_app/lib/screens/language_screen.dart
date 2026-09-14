import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 02 — Language Selection
/// 2-column large touch grid matching Stitch Screen 1 standards
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _languages = [
    (Language.english, 'English', 'English', 'Default clinical intake'),
    (Language.hindi, 'हिन्दी', 'Hindi', 'अपनी भाषा चुनें'),
    (Language.marathi, 'मराठी', 'Marathi', 'रुग्ण नोंदणी'),
    (Language.tamil, 'தமிழ்', 'Tamil', 'பதிவு தொடங்கவும்'),
    (Language.telugu, 'తెలుగు', 'Telugu', 'రోగి రిజిస్ట్రేషన్'),
    (Language.bengali, 'বাংলা', 'Bengali', 'ভাষা নির্বাচন করুন'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
        title: Text(state.tr('Language Selection', 'भाषा चयन')),
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
                          currentStep: 1,
                          totalSteps: 7,
                          stepLabel: 'Language Selection • भाषा चयन',
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.tr('Choose Your Language', 'अपनी भाषा चुनें'),
                              style: AppTextStyles.headlineLg,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '6 Regional Options',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Select the language you feel most comfortable speaking in with the doctor.',
                            'वह भाषा चुनें जिसमें आप डॉक्टर से बात करने में सबसे सहज महसूस करते हैं।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // 2-Column Responsive Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                          ),
                          itemCount: _languages.length,
                          itemBuilder: (ctx, i) {
                            final (lang, native, english, subtitle) = _languages[i];
                            final isSelected = state.language == lang;
                            return _LanguageGridCard(
                              nativeName: native,
                              englishName: english,
                              subtitle: subtitle,
                              isSelected: isSelected,
                              onTap: () => context.read<AppState>().setLanguage(lang),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Voice recognition note
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.record_voice_over,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.tr(
                                    'Our voice intake engine seamlessly understands clinical symptoms in natural mother tongues and mixed phrases (e.g. Hinglish).',
                                    'हमारा वॉयस इंजन स्वाभाविक मातृभाषा और मिश्रित बोलचाल (जैसे हिंग्लिश) में लक्षणों को आसानी से समझता है।',
                                  ),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'Confirm Language & Continue • आगे बढ़ें',
                            'भाषा पुष्टि करें और आगे बढ़ें',
                          ),
                          icon: Icons.arrow_forward,
                          onPressed: () => context.go('/consent'),
                        ),
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

class _LanguageGridCard extends StatelessWidget {
  final String nativeName;
  final String englishName;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageGridCard({
    required this.nativeName,
    required this.englishName,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nativeName,
                    style: AppTextStyles.headlineSm.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.surfaceContainerLow,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
