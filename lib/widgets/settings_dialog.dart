import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AlertDialog(
      backgroundColor: const Color(0xFF16213E),
      title: const Text(
        'Einstellungen',
        style: TextStyle(color: Colors.white),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Animationen', style: TextStyle(color: Colors.white70)),
          Switch(
            value: settings.animationsEnabled,
            onChanged: settings.setAnimationsEnabled,
            activeColor: const Color(0xFF533483),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
