import 'package:flutter/material.dart';
import 'details_page.dart'; 
import '../models/repertoire.dart';
import '../models/dossier.dart';

final _windowsPathRegex = RegExp(r'^[a-zA-Z]:\\[^<>:"/\\|?*\n\r]+(\\[^<>:"/\\|?*\n\r]+)*\\?$');



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remotePathController = TextEditingController();
  final _zipPathController = TextEditingController();
  final _localePathController = TextEditingController();

//Fonction de validation des chemins

  String? _validatePath(String? value){
    if(value == null || value.isEmpty){
      return "Please enter a valid path.";
    }
    if(!_windowsPathRegex.hasMatch(value)){
      return "Please enter a valid absolute path";
    }
    return null;
  }


  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      // Récupérer les chemins spécifiés
      final remotePath = _remotePathController.text;
      final zipPath = _zipPathController.text;
      final localePath = _localePathController.text;

       Repertoire remoteRepertoire = Dossier(path: remotePath);
      Repertoire zipRepertoire = Dossier(path: zipPath);
      Repertoire localRepertoire = Dossier(path: localePath);

      // Afficher le dialogue
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Instances créées'),
          content: const Text('Voulez-vous afficher les détails des répertoires créés ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Fermer le dialogue sans rien faire
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Aller vers la page des détails et passer les objets Repertoire
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DetailsPage(
                      remoteRepertoire: remoteRepertoire,
                      zipRepertoire: zipRepertoire,
                      localRepertoire: localRepertoire,
                    ),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _remotePathController,
                decoration: const InputDecoration(labelText: 'REMOTE Path'),
              validator: _validatePath,
              ),
              TextFormField(
                controller: _zipPathController,
                decoration: const InputDecoration(labelText: 'ZIP Path'),
            validator: _validatePath,
              ),
              TextFormField(
                controller: _localePathController,
                decoration: const InputDecoration(labelText: 'LOCALE Path'),
            validator: _validatePath,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Lancer la surveillance'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
