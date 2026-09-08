import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 02 — Language Selection
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const _languages = [
    (Language.hindi,   'हिन्दी',    'Hindi',   '🇮🇳'),
    (Language.english, 'English',   'English', '🔤'),
    (Language.telugu,  'తెలుగు',    'Telugu',  '🇮🇳'),
    (Language.tamil,   'தமிழ்',     'Tamil',   '🇮🇳'),
    (Language.bengali, 'বাংলা',     'Bengali', '🇮🇳'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                state.tr('Choose Your Language', 'अपनी भाषा चुनें'),
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.tr('Select the language you are most comfortable with.',
                         'वह भाषा चुनें जिसमें आप सबसे सहज महसूस करते हैं।'),
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (ctx, i) {
                    final (lang, native, english, flag) = _languages[i];
                    final selected = state.language == lang;
                    return _LanguageOption(
                      nativeLabel: native,
                      englishLabel: english,
                      flag: flag,
                      selected: selected,
                      onTap: () => context.read<AppState>().setLanguage(lang),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: state.tr('Continue', 'जारी रखें'),
                onPressed: () => context.go('/consent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String nativeLabel;
  final String englishLabel;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.nativeLabel,
    required this.englishLabel,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nativeLabel,
                      style: AppTextStyles.subheading.copyWith(
                          color: selected ? AppColors.brand : AppColors.textPrimary)),
                  Text(englishLabel, style: AppTextStyles.label),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.brand, size: 26),
          ],
        ),
      ),
    );
  }
}
