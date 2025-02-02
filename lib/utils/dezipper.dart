// ignore_for_file: avoid_print, use_rethrow_when_possible, unnecessary_import

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

Future<String> dezipper(String zipPath, String destinationPath) async {
  print('on va commencer le dezip');

  final inputStream = InputFileStream(zipPath);
  try {
    // Lecture du fichier ZIP avec un InputStream
    print("path au début du zip: $zipPath");
    final archive = ZipDecoder().decodeBuffer(inputStream);
    String firstExtractedPath = '';
    print("Archive $archive");
    // Extraction de chaque fichier
    for (var file in archive) {
      // Chemin normalisé pour le fichier/dossier extrait
      final filenameAtTheDestination =
          normalize(join(destinationPath, file.name));
      if (!filenameAtTheDestination.startsWith(destinationPath)) {
        throw Exception('Chemin invalide dans l\'archive: ${file.name}');
      }

      print("Chemin normalisé: $filenameAtTheDestination");

      if (file.isFile) {
        print("C'est un fichier");

        // Si c'est un fichier
        final outputFile = File(filenameAtTheDestination);

        // Créer le répertoire parent si nécessaire
        final parentDir = Directory(dirname(filenameAtTheDestination));
        if (!parentDir.existsSync()) {
          parentDir.createSync(recursive: true);
        }

        // Supprimer le fichier existant si besoin
        if (outputFile.existsSync()) {
          outputFile.deleteSync();
        }

        // Écrire le contenu du fichier
        final outputStream = OutputFileStream(filenameAtTheDestination);
        try {
          file.writeContent(outputStream);
        } finally {
          await outputStream.close();
        } // Fermer le flux après écriture
      } else {
        print("C'est un dossier");
        // Si c'est un répertoire, créer le répertoire
        final dir = Directory(filenameAtTheDestination);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      }

      if (firstExtractedPath.isEmpty) {
        firstExtractedPath = filenameAtTheDestination;
        print(
            "nom du fichier à la destination: $filenameAtTheDestination"); // Enregistrer le premier chemin extrait
      }
    }

    print("Dézippage du répertoire terminé");
    return firstExtractedPath;
  } catch (e) {
    print('Erreur lors du dézippage: $e');
    throw e;
  } finally {
    inputStream.close(); // Fermer le flux d'entrée après traitement
    //await Future.delayed(Duration(seconds: 15));

  }
}
