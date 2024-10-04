import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasPaths = prefs.containsKey('remotePath') &&
      prefs.containsKey('zipPath') &&
      prefs.containsKey('localePath');

  runApp(MyApp(showHomeScreen: !hasPaths));
}

class MyApp extends StatelessWidget {
  final bool showHomeScreen;
  const MyApp({super.key, required this.showHomeScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Files Handler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: showHomeScreen ? const HomeScreen() : const BackgroundService(),
    );
  }
}
