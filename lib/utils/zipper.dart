import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';

Future<String> zipper(String inputPath, String destinationPath) async {
  try {
    final entity = FileSystemEntity.typeSync(inputPath);

    if (entity == FileSystemEntityType.notFound) {
      return "Le chemin spécifié n'existe pas";
    }

    final archive = Archive();

    if (entity == FileSystemEntityType.file) {
      try {
        final file = File(inputPath);
        final fileData = file.readAsBytesSync();
        final relativePath = file.uri.pathSegments.last; // Nom du fichier
        final archiveFile = ArchiveFile(relativePath, fileData.length, fileData);
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
          await File(destinationPath).writeAsBytes(encodedArchive);
        }

        return zipFilePath;
      } catch (e) {
        print("Erreur lors du zippage du fichier: $e");
        return 'Erreur lors du zippage du fichier: $e';
      }
    } else if (entity == FileSystemEntityType.directory) {
      final directory = Directory(inputPath);

      void addDirectoryToArchive(Directory dir, String baseDir) {
        for (var subEntity in dir.listSync(recursive: true)) {
          if (subEntity is File) {
            final fileData = subEntity.readAsBytesSync();
            final relativePath = subEntity.path.substring(baseDir.length + 1);
            // Ajouter le fichier à l'archive avec son chemin relatif
            archive.addFile(ArchiveFile(relativePath, fileData.length, fileData));
          } else if (subEntity is Directory) {
            // Si c'est un sous-répertoire, ajouter récursivement
            addDirectoryToArchive(subEntity, baseDir);
          }
        }
      }

      // Ajouter le répertoire racine à l'archive
      addDirectoryToArchive(directory, inputPath);

      // Créer le fichier zip
      final zipFilePath = destinationPath;
      final zipFile = File(zipFilePath);
      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      final zipEncoder = ZipEncoder();
      final encodedArchive = zipEncoder.encode(archive);

      if (encodedArchive != null) {
        await File(destinationPath).writeAsBytes(encodedArchive);
      }

      return zipFilePath;
    } else {
      return "Type de chemin inconnu";
    }
  } catch (e) {
    print('Erreur lors du zippage: $e');
    return 'Erreur lors du zippage: $e';
  }
}
