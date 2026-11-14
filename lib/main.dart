import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/settings_service.dart';
import 'screens/setup_screen.dart';
import 'screens/game_screen.dart';
import 'screens/scoreboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/rules_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsProvider = SettingsProvider(SettingsService());
  await settingsProvider.load();
  final gameProvider = GameProvider(StorageService())
    ..streakRuleEnabled = settingsProvider.streakMultiplierEnabled;
  settingsProvider.addListener(() {
    gameProvider.streakRuleEnabled = settingsProvider.streakMultiplierEnabled;
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const MatrixApp(),
    ),
  );
}

class MatrixApp extends StatelessWidget {
  const MatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix – Das Kartentrinkspiel',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SetupScreen(),
        '/game': (context) => const GameScreen(),
        '/scoreboard': (context) => const ScoreboardScreen(),
        '/history': (context) => const HistoryScreen(),
        '/rules': (context) => const RulesScreen(),
      },
    );
  }
}
