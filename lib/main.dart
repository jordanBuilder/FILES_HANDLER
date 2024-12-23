import 'dart:io';

import 'package:files_handler/handlers/event_handler.dart';
import 'package:files_handler/handlers/event_watcher.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:system_tray/system_tray.dart';
import 'models/repertoire.dart';
import 'screens/tinyWindow.dart';
import 'screens/home_screen.dart';

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

    List<String> repertoirePaths = [remotePath, zipPath, localePath];

    final List<EventWatcher> watchers = [];

    final zipRepertoire = Repertoire(zipPath);
    final remoteRepertoire = Repertoire(remotePath);
    final localeRepertoire = Repertoire(localePath);

    for (String path in repertoirePaths) {
      final directory = Directory(path);
      if (directory.existsSync()) {

        final eventHandlers = EventHandlers();

        final watcher = EventWatcher(directory, eventHandlers, zipRepertoire, remoteRepertoire, localeRepertoire);

        watchers.add(watcher);

        watcher.startWatching();

        print("Surveillance démarrée pour $path");
      }
    }

    runApp(MyApp(
      showHomeScreen: false,
    ));

    doWhenWindowReady(() {
      // final win = appWindow;
      // win.hide(); // Cache la fenêtre au démarrage
      // initializeSystemTray(win as AppWindow); // Initialise le system tray
    });
  } else {
    runApp(MyApp(showHomeScreen: true));
  }
}

void initializeSystemTray(AppWindow win) async {
  final systemTray = SystemTray();

  // Configuration de l'icône
  const String iconPath =
      'assets/images/appIcon.png'; // Remplace par le chemin de ton icône
  await systemTray.initSystemTray(
    title: "Files Handler",
    iconPath: iconPath,
  );

  // Configuration du menu
  final menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(
      label: 'Afficher',
      onClicked: (menuItem) => win.show(),
    ),
    MenuItemLabel(
      label: 'Quitter',
      onClicked: (menuItem) => appWindow.close(),
    ),
  ]);

  await systemTray.setContextMenu(menu);

  // Gérer le clic gauche sur l'icône
  // systemTray.set((event) {
  //   if (event == "click") {
  //     win.show();
  //   }
  // });
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
              })
            : TinyWindow(
                onResetPaths: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('remotePath');
                  await prefs.remove('zipPath');
                  await prefs.remove('localePath');
                },
              ));
  }
}
