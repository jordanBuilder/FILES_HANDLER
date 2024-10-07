// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:files_handler/models/repertoire.dart';

class TinyWindow extends StatefulWidget {
  final Repertoire remoteRepertoire;
  final Repertoire zipRepertoire;
  final Repertoire localRepertoire;
  final VoidCallback onResetPaths;

  const TinyWindow({
    Key? key,
    required this.remoteRepertoire,
    required this.zipRepertoire,
    required this.localRepertoire,
    required this.onResetPaths,
  }) : super(key: key);

  @override
  _TinyWindowState createState() => _TinyWindowState();
}

class _TinyWindowState extends State<TinyWindow> {
  @override
  void initState() {
    super.initState();
    doWhenWindowReady(() {
      final win = appWindow;
      win.minSize = Size(200, 150); // Définir la taille minimale de la fenêtre
      win.size = Size(200, 150); // Définir la taille initiale de la fenêtre
      win.alignment = Alignment
          .bottomRight; // Placer la fenêtre dans le coin inférieur droit
      win.show();
    });

    widget.remoteRepertoire.ecouterEvenements(
      widget.remoteRepertoire,
      widget.zipRepertoire,
      widget.localRepertoire,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye),
                onPressed: () {
                  appWindow.hide();
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: widget.onResetPaths,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[500],
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black),
                  ),
                  child: const Text(
                    'REDEFINIR LES CHEMINS',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
