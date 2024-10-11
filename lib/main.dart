// ignore_for_file: prefer_const_constructors

import 'package:files_handler/screens/tinyWindow.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'models/repertoire.dart'; // Les modèles de Répertoire
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasPaths = prefs.containsKey('remotePath') &&
      prefs.containsKey('zipPath') &&
      prefs.containsKey('localePath');

  if (hasPaths) {
    final remotePath = prefs.getString('remotePath')!;
    final zipPath = prefs.getString('zipPath')!;
    final localePath = prefs.getString('localePath')!;

    Repertoire remoteRepertoire = Repertoire(path: remotePath);
    Repertoire zipRepertoire = Repertoire(path: zipPath);
    Repertoire localRepertoire = Repertoire(path: localePath);

    remoteRepertoire.ecouterEvenements(
        remoteRepertoire, zipRepertoire, localRepertoire);

    runApp(MyApp(
      showHomeScreen: false,
      remoteRepertoire: remoteRepertoire,
      zipRepertoire: zipRepertoire,
      localRepertoire: localRepertoire,
    ));
   
  } else {
    // Si les chemins ne sont pas présents, afficher la HomeScreen pour entrer les chemins
    runApp(MyApp(showHomeScreen: true));
    
    doWhenWindowReady(() {
      final win = appWindow;
      win.minSize = Size(800, 700); // Taille minimale pour HomeScreen
      win.size = Size(900, 600); // Taille initiale par défaut
      win.alignment = Alignment.center; // Centrer la fenêtre

      win.show();
    });
  }
}

class MyApp extends StatelessWidget {
  final bool showHomeScreen;
  final Repertoire? remoteRepertoire;
  final Repertoire? zipRepertoire;
  final Repertoire? localRepertoire;

  const MyApp({
    super.key,
    required this.showHomeScreen,
    this.remoteRepertoire,
    this.zipRepertoire,
    this.localRepertoire,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Files Handler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: showHomeScreen
          ? HomeScreen(onResetPaths: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('remotePath');
              await prefs.remove('zipPath');
              await prefs.remove('localePath');
              runApp(const MyApp(showHomeScreen: true));
            })
          : TinyWindow(
             remoteRepertoirePath: remoteRepertoire!.path,
             zipRepertoirePath: zipRepertoire!.path,
             localRepertoirePath: localRepertoire!.path,
              onResetPaths: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('remotePath');
                await prefs.remove('zipPath');
                await prefs.remove('localePath');
                runApp(const MyApp(showHomeScreen: false));
              },
            ), // Afficher la DetailsPage si les chemins sont présents
    );
  }
}
