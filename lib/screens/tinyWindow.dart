import 'package:files_handler/models/repertoire.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class TinyWindow extends StatefulWidget {
  final String remoteRepertoirePath;
  final String zipRepertoirePath;
  final String localRepertoirePath;
  final Function onResetPaths; // Changez le type de onResetPaths en Function

  const TinyWindow({
    Key? key,
    required this.remoteRepertoirePath,
    required this.zipRepertoirePath,
    required this.localRepertoirePath,
    required this.onResetPaths,
  }) : super(key: key);

  @override
  _TinyWindowState createState() => _TinyWindowState();
}

class _TinyWindowState extends State<TinyWindow> {
  late Repertoire remoteRepertoire;
  late Repertoire zipRepertoire;
  late Repertoire localRepertoire;

  @override
  void initState() {
    super.initState();
    
    // Initialisation des instances de Dossier avec les chemins fournis
  
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
              Flexible(
                child: IconButton(
                  icon: const Icon(Icons.remove_red_eye),
                  onPressed: () {
                    appWindow.hide();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => widget.onResetPaths(),
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
