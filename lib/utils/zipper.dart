import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';
  
  
  Future<String> zipper(String filePath, String destinationPath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return 'Le fichier spécifié n\'existe pas.';
      }

      // Lire les données du fichier
      final fileData = file.readAsBytesSync();
      final archiveFile = ArchiveFile(filePath, fileData.length, fileData);
      final archive = Archive();

      // Ajouter le fichier à l'archive
      archive.addFile(archiveFile);

      // Créer le fichier zip
      final zipFilePath = destinationPath;
      final zipFile = File(zipFilePath);
      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      final zipEncoder = ZipEncoder();
      final encodedArchive = zipEncoder.encode(archive);

      if (encodedArchive != null) {
        final zipFile =
            await File(destinationPath).writeAsBytes(encodedArchive);
      }

      return zipFilePath;
    } catch (e) {
      print('Erreur lors du zippage: $e');
      return 'Erreur lors du zippage: $e';
    }
  }