// ignore_for_file: deprecated_export_use

import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

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
        final inputStream = file.openRead();
        final relativePath = file.uri.pathSegments.last;

        final buffer = BytesBuilder();

        var archiveFile = ArchiveFile(relativePath, 0, null);
        archive.addFile(archiveFile);

        await for (final chunk in inputStream) {
          buffer.add(chunk);
        }

        archiveFile =
            ArchiveFile(relativePath, buffer.length, buffer.toBytes());
        archive.addFile(archiveFile);

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

      Future<void> addDirectoryToArchive(Directory dir, String baseDir) async {
        for (var subEntity in dir.listSync(recursive: true)) {
          if (subEntity is File) {
            final inputStream = subEntity.openRead();
            final relativePath = subEntity.path.substring(baseDir.length + 1);

            var archiveFile = ArchiveFile(relativePath, 0, null);
            archive.addFile(archiveFile);

            final buffer = BytesBuilder();

            await for (final chunk in inputStream) {
              buffer.add(chunk);
            }

            archiveFile =
                ArchiveFile(relativePath, buffer.length, buffer.toBytes());
            archive.addFile(archiveFile);
          } else if (subEntity is Directory) {
            addDirectoryToArchive(subEntity, baseDir);
          }
        }
      }

     await addDirectoryToArchive(directory, inputPath);

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
