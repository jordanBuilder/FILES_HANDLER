// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

Future<String> dezipper(String zipPath, String destinationPath) async {
  try {
    // Lecture du fichier ZIP avec un InputStream
    final inputStream = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    String firstExtractedPath = '';

    // Extraction de chaque fichier
    for (var file in archive.files) {
      final filename = join(destinationPath, file.name);

      if (file.isFile) {
        final outputFile = File(filename);
        if (outputFile.existsSync()) {
          outputFile.deleteSync();
        }
        final outputStream = OutputFileStream(filename);
        file.writeContent(outputStream);
        // S'assurer que le répertoire parent existe
        // Copie du contenu dans le flux de sortie
        await outputStream.close(); // Fermer le flux après écriture
      } else {
        // Créer le répertoire
        final dir = Directory(filename);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      }

      if (firstExtractedPath.isEmpty) {
        firstExtractedPath = filename;
      }
    }

    inputStream.close(); // Fermer le flux d'entrée après traitement

    print("Dézippage du répertoire terminé");
    return firstExtractedPath;
  } catch (e) {
    print('Erreur lors du dézippage: $e');
    // Relancer l'erreur pour que la méthode retourne une erreur
    throw e;
  }
}
