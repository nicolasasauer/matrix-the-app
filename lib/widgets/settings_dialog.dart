import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// The toggleable house rules and options. Used on the start screen and in
/// the in-game settings dialog.
class HouseRulesList extends StatelessWidget {
  const HouseRulesList({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return Column(
      children: [
        _RuleRow(
          title: AppStrings.streakRuleTitle,
          description: AppStrings.streakRuleDescription,
          value: s.streakMultiplierEnabled,
          onChanged: s.setStreakMultiplierEnabled,
        ),
        const Divider(height: 1, color: AppColors.line),
        _RuleRow(
          title: AppStrings.probabilitiesTitle,
          description: AppStrings.probabilitiesDescription,
          value: s.showProbabilities,
          onChanged: s.setShowProbabilities,
        ),
        const Divider(height: 1, color: AppColors.line),
        _RuleRow(
          title: AppStrings.animations,
          description: AppStrings.animationsDescription,
          value: s.animationsEnabled,
          onChanged: s.setAnimationsEnabled,
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RuleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.body(14, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: AppText.body(11.5,
                            color: AppColors.muted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.raised,
      title: Text(AppStrings.settingsTitle, style: AppText.display(22)),
      content: const SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(child: HouseRulesList()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.done,
              style: AppText.body(14,
                  weight: FontWeight.w600, color: AppColors.amber)),
        ),
      ],
    );
  }
}
