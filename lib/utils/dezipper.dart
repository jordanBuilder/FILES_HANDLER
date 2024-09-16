import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'package:files_handler/utils/deplacer.dart';
import 'package:files_handler/utils/zipper.dart';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';

  
  Future<String> dezipper(String zipPath, String destinationPath) async {
    try {
      // Lecture de l'archive
      final archiveBytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(archiveBytes);

      String firstExtractedPath = '';

      // Extraction de chaque fichier
      for (final file in archive) {
        final filename = join(destinationPath, file.name);

        if (file.isFile) {
          // S'assurer que le répertoire parent existe
          final outFile = File(filename);
          final parentDir = outFile.parent;

          // Créer les répertoires parents s'ils n'existent pas
          if (!parentDir.existsSync()) {
            parentDir.createSync(recursive: true);
          }

          // Si le fichier existe, le supprimer avant d'écrire le nouveau fichier
          if (outFile.existsSync()) {
            outFile.deleteSync();
          }

          // Écrire le contenu du fichier
          await outFile.writeAsBytes(file.content);
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
      print("dezippage du repertoire terminé");
      return firstExtractedPath;
    } catch (e) {
      print('Erreur lors du dézippage: $e');
      // Relancer l'erreur pour que la méthode retourne une erreur
      throw e;
    }
  }