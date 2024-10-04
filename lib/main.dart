import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/details_page.dart'; // La page des détails
import 'models/repertoire.dart'; // Les modèles de Répertoire
import 'models/dossier.dart'; // Le modèle Dossier qui hérite de Répertoire
import 'package:win32/win32.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Vérifier si les chemins sont présents dans le SharedPreferences
  final hasPaths = prefs.containsKey('remotePath') &&
                   prefs.containsKey('zipPath') &&
                   prefs.containsKey('localePath');

  if (hasPaths) {

    final hWnd = GetConsoleWindow();
  ShowWindow(hWnd, SHOW_WINDOW_CMD.SW_HIDE);

    // Si les chemins existent, les récupérer
    final remotePath = prefs.getString('remotePath')!;
    final zipPath = prefs.getString('zipPath')!;
    final localePath = prefs.getString('localePath')!;
    
    // Créer les objets Répertoire avec les chemins récupérés
    Repertoire remoteRepertoire = Dossier(path: remotePath);
    Repertoire zipRepertoire = Dossier(path: zipPath);
    Repertoire localRepertoire = Dossier(path: localePath);

    // Lancer l'application et diriger vers la DetailsPage
    runApp(MyApp(
      showHomeScreen: false, // Ne pas montrer la HomeScreen, mais la DetailsPage
      remoteRepertoire: remoteRepertoire,
      zipRepertoire: zipRepertoire,
      localRepertoire: localRepertoire,
    ));

   
  } else {
    // Si les chemins ne sont pas présents, afficher la HomeScreen pour entrer les chemins
    runApp(MyApp(showHomeScreen: true));
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
        ? const HomeScreen() // Afficher la HomeScreen si les chemins ne sont pas présents
        : DetailsPage(
            remoteRepertoire: remoteRepertoire!, // Passer les répertoires
            zipRepertoire: zipRepertoire!,
            localRepertoire: localRepertoire!,
          ), // Afficher la DetailsPage si les chemins sont présents
    );
  }
}
