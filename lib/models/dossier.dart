// ignore_for_file: unused_import

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';
import 'repertoire.dart';

class Dossier extends Repertoire {
  late int
      nombreDeFichiers; // Assurez-vous que 'nombreDeFichiers' est initialisé correctement

  Dossier({
    required String path,
    List<String> permissions =
        const [], // Valeur par défaut pour les permissions
    this.nombreDeFichiers = 0,
  }) : super(path: path) {
    // Assurez-vous que les propriétés héritées sont correctement initialisées
    this.permissions = permissions;
    initializeProperties(); // Initialise les propriétés héritées
  }

  @override
  void initializeProperties() {
    super.initializeProperties(); // Appel au constructeur de la classe parent

    // Le type pour un Dossier est toujours 'dossier', mais vous pouvez ajouter plus de logique ici si nécessaire
    type = 'dossier';
  }

  String ajouterFichierDansDossier(String filePath) {
    ajouterFichier(filePath);
    nombreDeFichiers++;
    return "Fichier ajouté dans le dossier. Nombre total de fichiers : $nombreDeFichiers";
  }
}
