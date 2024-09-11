import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';
import 'repertoire.dart';

class Dossier extends Repertoire {
  int nombreDeFichiers;

  Dossier({
    required String name,
    required String path,
    required int size,
    required bool status,
    required List<String> permissions,
    this.nombreDeFichiers = 0,
  }) : super(
            name: name,
            path: path,
            size: size,
            status: status,
            permissions: permissions);

  String ajouterFichierDansDossier(String filePath) {
    ajouterFichier(filePath);
    nombreDeFichiers++;
    return "Fichier ajouté dans le dossier. Nombre total de fichiers : $nombreDeFichiers";
  }
}
