import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';

class Repertoire {
  String name;
  String path;
  int size;
  bool status;
  List<String> permissions;

  Repertoire(
      {required this.name,
      required this.path,
      required this.size,
      this.status = false,
      required this.permissions});

  //Methode pour zipper un fichier

  String zipper(String sourcePath, String destinationPath) {
    try {
      final encoder = ZipFileEncoder();
      encoder.zipDirectory(Directory(sourcePath), filename: destinationPath);
      return "Zippage du répertoire/fichier termniné.";
    } catch (e) {
      return "Erreur lors du zippage: $e";
    }
  }

  //Methode pour ajouter un fichier

  String ajouterFichier(String filePath) {
    try {
      File(filePath).createSync();
      return "Fichier ajouté avec succés.";
    } catch (e) {
      return "Erreur lors de l\'ajout du fichier: $e";
    }

    Stream<FileSystemEvent> surveiller(String folderPath) {
      final dir = Directory(folderPath);
      return dir.watch();
    }

    String ajouterPermissions(String permission) {
      permissions.add(permission);
    }
  }
}
