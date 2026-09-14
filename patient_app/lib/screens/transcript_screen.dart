import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../state/app_state.dart';

/// Screen 07 — Structured Symptom Review
/// Matches Stitch Screen 3 standards: Audio voice note player, Restrained Urgent Red Alert banner,
/// structured clinical finding cards with provenance badges and inline editing.
class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  bool _isPlaying = false;

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _showEditFindingDialog(int index, String fieldType, String currentValue) {
    final state = context.read<AppState>();
    final ctrl = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          '${state.tr('Edit', 'संशोधित करें')} ${_formatFieldTitle(fieldType)}',
          style: AppTextStyles.headlineSm,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.tr('Update the recorded finding:', 'दर्ज जानकारी को अपडेट करें:'),
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              state.tr('Cancel', 'रद्द करें'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                state.updateFinding(index, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text(state.tr('Save', 'सहेजें')),
          ),
        ],
      ),
    );
  }

  String _formatFieldTitle(String key) {
    switch (key.toLowerCase()) {
      case 'chief_complaint':
        return 'Chief Complaint / मुख्य शिकायत';
      case 'duration':
        return 'Duration & Progression / समयावधि';
      case 'severity':
        return 'Severity & Quality / गंभीरता';
      case 'radiation':
        return 'Radiation Site / दर्द का फैलाव';
      case 'associated':
        return 'Associated Symptoms / जुड़े लक्षण';
      case 'hpi':
        return 'Clinical HPI Summary / नैदानिक सारांश';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Fallback if findings are empty
    final findings = state.findings.isNotEmpty
        ? state.findings
        : [
            ClinicalFinding(fieldType: 'chief_complaint', value: 'Chest Pain', source: 'patient_reported'),
            ClinicalFinding(fieldType: 'duration', value: '2 hours', source: 'patient_reported'),
            ClinicalFinding(fieldType: 'severity', value: 'Severe', source: 'patient_reported'),
            ClinicalFinding(fieldType: 'radiation', value: 'Left arm', source: 'patient_reported'),
            ClinicalFinding(fieldType: 'associated', value: 'Sweating', source: 'patient_reported'),
          ];

    final transcriptText = state.transcript.isNotEmpty
        ? state.transcript
        : 'मरीज ने बताया कि दो घंटे से सीने में तेज दर्द है, जो बाएं हाथ की तरफ जा रहा है और पसीना आ रहा है...';

    // Red flag detection check
    final isUrgentAlert = state.hasUrgentRedFlag ||
        findings.any((f) =>
            f.fieldType.toLowerCase() == 'chief_complaint' &&
            f.value.toLowerCase().contains('chest'));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/voice-interview'),
        ),
        title: Text(state.tr('Symptom Review', 'लक्षण समीक्षा')),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Session: #${state.encounterId?.substring(0, 8) ?? 'AS-8942'}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
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
                        const FlowProgressIndicator(
                          currentStep: 6,
                          totalSteps: 7,
                          stepLabel: 'Clinical Review • नैदानिक समीक्षा',
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        Text(
                          state.tr('Structured Symptom Review', 'लक्षणों की व्यवस्थित समीक्षा'),
                          style: AppTextStyles.headlineLg,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.tr(
                            'Please verify the clinical details extracted from your spoken response before consultation.',
                            'परामर्श से पहले कृपया अपनी बातचीत से निकाली गई स्वास्थ्य जानकारी की पुष्टि करें।',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Spoken Voice Note Replay Tile (Matching Stitch Screen 3)
                        ClinicalCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.mic, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        state.tr('Spoken Note: 38 sec', 'रिकॉर्ड किया गया ऑडियो (38 सेकंड)'),
                                        style: AppTextStyles.labelLarge,
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ABDM Encrypted',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Audio Playback bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: _togglePlay,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Waveform bars
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(24, (i) {
                                          final h = 6.0 + ((i * 7) % 18);
                                          final isFilled = i < 14;
                                          return Container(
                                            width: 3,
                                            height: h,
                                            decoration: BoxDecoration(
                                              color: isFilled
                                                  ? AppColors.primary
                                                  : AppColors.primary.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '00:38',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),
                              Text(
                                '"$transcriptText"',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Restrained Urgent Red Alert Banner (Strict 4px Left-Bar Clinical Motif)
                        if (isUrgentAlert) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const RestrainedAlertBanner(
                            title: 'Emergency Symptom Pattern Triage Alert',
                            message:
                                'Patient noted episodic chest pressure with exertion. Immediate clinical vitals check and ECG scheduled for physician triage.',
                            criteria: ['Chest Pain', 'Severe', 'Radiation to left arm', 'Sweating'],
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.tr('Structured Information', 'व्यवस्थित जानकारी'),
                              style: AppTextStyles.headlineSm,
                            ),
                            Text(
                              '${findings.length} ${state.tr('data points identified', 'लक्षण दर्ज')}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Structured Cards List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: findings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, i) {
                            final finding = findings[i];
                            return ClinicalCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${i + 1}. ${_formatFieldTitle(finding.fieldType)}',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SourceBadge(source: finding.source),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          finding.value,
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                    onPressed: () => _showEditFindingDialog(
                                      i,
                                      finding.fieldType,
                                      finding.value,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        PrimaryButton(
                          label: state.tr(
                            'Confirm Symptoms & Continue • आगे बढ़ें',
                            'लक्षणों की पुष्टि करें और आगे बढ़ें',
                          ),
                          icon: Icons.arrow_forward,
                          onPressed: () => context.go('/medical-history'),
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
