import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'services/storage_service.dart';
import 'screens/setup_screen.dart';
import 'screens/game_screen.dart';
import 'screens/scoreboard_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameProvider(StorageService()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF533483),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SetupScreen(),
        '/game': (context) => const GameScreen(),
        '/scoreboard': (context) => const ScoreboardScreen(),
      },
    );
  }
}
