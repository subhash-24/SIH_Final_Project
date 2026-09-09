import 'package:flutter/material.dart';

/// Arogya-Saathi Patient App — Design System
/// Calm, accessible, large-text, touch-friendly

class AppColors {
  // Brand
  static const brand = Color(0xFF1A6B6B);        // Deep teal
  static const brandLight = Color(0xFFE8F4F4);   // Teal tint bg
  static const brandMuted = Color(0xFFB2D8D8);   // Teal muted

  // Background
  static const bg = Color(0xFFFAFAF8);            // Warm white
  static const surface = Color(0xFFFFFFFF);        // Pure white
  static const surfaceAlt = Color(0xFFF5F6F4);     // Light neutral

  // Text
  static const textPrimary = Color(0xFF1C1C1E);    // Deep charcoal
  static const textSecondary = Color(0xFF6B7280);  // Medium gray
  static const textMuted = Color(0xFF9CA3AF);      // Light gray

  // Semantic
  static const urgent = Color(0xFFB91C1C);         // Deep red
  static const urgentBg = Color(0xFFFEF2F2);
  static const warning = Color(0xFFD97706);        // Amber
  static const success = Color(0xFF065F46);        // Deep green
  static const successBg = Color(0xFFECFDF5);

  // Border
  static const border = Color(0xFFE5E7EB);
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const question = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.brand,
      surface: AppColors.surface,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

// ── Common Widgets ─────────────────────────────────────────────────────────

/// Large primary CTA button — used for main actions
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.brandMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(label, style: AppTextStyles.buttonLarge),
                ],
              ),
      ),
    );
  }
}

/// Secondary outlined button
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provenance/source badge
class SourceBadge extends StatelessWidget {
  final String source;

  const SourceBadge({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _data();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg,
              letterSpacing: 0.3)),
    );
  }

  (String, Color, Color) _data() => switch (source) {
    'ai_extracted' => ('AI Extracted', const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
    'patient_reported' => ('Patient Reported', const Color(0xFFF3F4F6), const Color(0xFF374151)),
    'document_extracted' => ('Doc Extracted', const Color(0xFFF5F3FF), const Color(0xFF6D28D9)),
    'physician_confirmed' => ('Physician Confirmed', const Color(0xFFECFDF5), const Color(0xFF065F46)),
    _ => ('Needs Review', const Color(0xFFFFFBEB), const Color(0xFF92400E)),
  };
}

/// Progress indicator — shows flow step
class FlowProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepLabel;

  const FlowProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(stepLabel, style: AppTextStyles.caption),
            const Spacer(),
            Text('$currentStep of $totalSteps', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
