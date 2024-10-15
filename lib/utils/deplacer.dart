// ignore_for_file: avoid_print, unused_local_variable, unnecessary_brace_in_string_interps, depend_on_referenced_packages
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';

Future<String> deplacer(String sourcePath, String destinationDirPath) async {
  try {
    print("truc à deplacer  : $sourcePath");
    sourcePath = normalize(sourcePath);
    destinationDirPath = normalize(destinationDirPath);
    final entityType = FileSystemEntity.typeSync(sourcePath);
    print("type de ce que je veux deplacer : $entityType");
    // Créer l'objet Directory pour le répertoire de destination
    final destinationDir = Directory(destinationDirPath);

    // Vérifier si le répertoire de destination existe, sinon le créer
    if (!destinationDir.existsSync()) {
      destinationDir.createSync(recursive: true);
    }

    if (entityType == FileSystemEntityType.file) {
      // Si c'est un fichier
      final sourceFile = File(sourcePath);
      final fileName = basename(sourcePath); // Récupère le nom du fichier
      final destinationFilePath = join(destinationDirPath, fileName);

      // Si un fichier avec le même nom existe déjà à l'emplacement de destination, le supprimer
      if (File(destinationFilePath).existsSync()) {
        File(destinationFilePath).deleteSync();
        print("Fichier existant à supprimer: $destinationFilePath");
      }

      final inputStream = sourceFile.openRead(); // Lire le fichier source
      final outputStream = File(destinationFilePath)
          .openWrite(); // Écrire dans le fichier de destination

      // Copier le contenu du fichier par morceaux
      await inputStream.pipe(outputStream);

      // Supprimer le fichier source après la copie
      await sourceFile.delete();

      print("Fichier déplacé avec succès vers $destinationFilePath");
      return "Fichier déplacé avec succès vers $destinationFilePath";
    } else if (entityType == FileSystemEntityType.directory) {
      // Si c'est un dossier
      print(sourcePath);
      final sourceDir = Directory(sourcePath);
      print("sourceDir: $sourceDir");
      final dirName = basename(sourcePath); // Récupère le nom du dossier
      print("basename: $dirName");
      final destinationFolderPath = join(destinationDirPath, dirName);
      print(
          "dossier destination pour le deplacement : ${destinationFolderPath}");

      // Si un dossier avec le même nom existe déjà à l'emplacement de destination, le supprimer
      if (Directory(join(destinationFolderPath)).existsSync()) {
        Directory(destinationFolderPath).deleteSync(recursive: true);
        print("Dossier existant supprimé: $destinationFolderPath");
      }

      // Renommer le dossier (déplacer)
      sourceDir.renameSync(destinationFolderPath);
      //  await copyDirectory(sourceDir,destinationDir);

      print("Dossier déplacé avec succès vers $destinationFolderPath");

      return "Dossier déplacé avec succès vers $destinationFolderPath";
    } else {
      return "Le chemin spécifié n'est ni un fichier ni un répertoire.";
    }
  } catch (e) {
    print("Erreur lors du déplacement: $e");
    return "Erreur lors du déplacement: $e";
  }
}
