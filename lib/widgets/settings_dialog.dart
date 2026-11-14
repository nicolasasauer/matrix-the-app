import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text(
        AppStrings.settingsTitle,
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              AppStrings.animations,
              style: TextStyle(color: Colors.white70),
            ),
            value: settings.animationsEnabled,
            onChanged: settings.setAnimationsEnabled,
            activeColor: const Color(0xFF533483),
          ),
          const Divider(color: Colors.white12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              AppStrings.streakRuleTitle,
              style: TextStyle(color: Colors.white70),
            ),
            subtitle: const Text(
              AppStrings.streakRuleDescription,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            value: settings.streakMultiplierEnabled,
            onChanged: settings.setStreakMultiplierEnabled,
            activeColor: const Color(0xFF533483),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.done,
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
