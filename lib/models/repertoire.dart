import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';

enum RepertoireStatus {
  surveille,
  nonSurveille,
}

class Repertoire {
  late String name;
  late String path;
  late int size;
  late RepertoireStatus status;
  late String type;
  List<String> permissions = [];

  Repertoire({required this.path}){
    status = RepertoireStatus.nonSurveille;
    initializeProperties();
  }

  void initializeProperties() {
    final fileStat = FileStat.statSync(path);

    // Déterminer si le chemin pointe vers un fichier ou un répertoire
    if (FileSystemEntity.isDirectorySync(path)) {
      name = basename(path); // Le nom du dossier
      type = 'dossier'; // Si c'est un répertoire
    } else if (FileSystemEntity.isFileSync(path)) {
      name = basename(path); // Le nom du fichier
      type = 'fichier'; // Si c'est un fichier
    } else {
      type = 'inconnu'; // Si le type est inconnu ou le fichier n'existe pas
    }

    size = fileStat.size;
  }

void changerStatut(RepertoireStatus nouveauStatut) {
    status = nouveauStatut;
  }
  
  //Methode pour zipper un fichier
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  String zipper(String destinationPath) {
    try {
      final file = File(path);
      final encoder = ZipFileEncoder();
      final archive = Archive();

      if (file.existsSync()) {
        final fileData = file.readAsBytesSync();
        archive.addFile(ArchiveFile(name, fileData.length, fileData));

        final zipFile = File(destinationPath);

        if (zipFile.existsSync()) {
          zipFile.deleteSync();
        }

        final zipEncoder = ZipFileEncoder();
        zipEncoder.create(zipFile.path);
        zipEncoder.addFile(file);
        zipEncoder.close();

        return 'Zippage du fichier terminé.';
      } else {
        return 'Le fichier spécifié n\'existe pas.';
      }
    } catch (e) {
      return 'Erreur lors du zippage: $e';
    }
  }

  String dezipper(String zipPath, String destinationPath) {
    try {
      // Lecture de l'archive
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

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
          outFile.writeAsBytesSync(file.content);
        } else {
          // Créer le répertoire
          Directory(filename).createSync(recursive: true);
        }
      }

      return 'Dézippage du fichier terminé.';
    } catch (e) {
      return 'Erreur lors du dézippage: $e';
    }
  }

  String copier(String sourceFilePath, String destinationDirPath) {
    try {
      // Créer l'objet File pour le fichier source
      final sourceFile = File(sourceFilePath);

      // Vérifier si le fichier source existe
      if (!sourceFile.existsSync()) {
        return "Le fichier source n'existe pas.";
      }

      // Créer l'objet Directory pour le répertoire de destination
      final destinationDir = Directory(destinationDirPath);

      // Vérifier si le répertoire de destination existe, sinon le créer
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }

      // Construire le chemin complet du fichier de destination
      final fileName = basename(
          sourceFilePath); // Récupère le nom du fichier depuis le chemin source
      final destinationFilePath = join(destinationDirPath, fileName);

      // Copier le fichier
      sourceFile.copySync(destinationFilePath);

      return "Fichier copié avec succès vers $destinationFilePath";
    } catch (e) {
      return "Erreur lors de la copie du fichier: $e";
    }
  }

  String deplacer(String sourceFilePath, String destinationDirPath) {
    try {
      // Créer l'objet File pour le fichier source
      final sourceFile = File(sourceFilePath);

      // Vérifier si le fichier source existe
      if (!sourceFile.existsSync()) {
        return "Le fichier source n'existe pas.";
      }

      // Créer l'objet Directory pour le répertoire de destination
      final destinationDir = Directory(destinationDirPath);

      // Vérifier si le répertoire de destination existe, sinon le créer
      if (!destinationDir.existsSync()) {
        destinationDir.createSync(recursive: true);
      }

      // Construire le chemin complet du fichier de destination
      final fileName = basename(
          sourceFilePath); // Récupère le nom du fichier depuis le chemin source
      final destinationFilePath = join(destinationDirPath, fileName);

      // Déplacer le fichier
      sourceFile.renameSync(destinationFilePath);

      return "Fichier déplacé avec succès vers $destinationFilePath";
    } catch (e) {
      return "Erreur lors du déplacement du fichier: $e";
    }
  }

  String ajouterFichier(String filePath) {
    try {
      File(filePath).createSync();
      return "Fichier ajouté avec succés.";
    } catch (e) {
      return "Erreur lors de l\'ajout du fichier: $e";
    }
  }

  Stream<FileSystemEvent> surveiller(String folderPath) {
    final dir = Directory(folderPath);
    return dir.watch();
  }

  String ajouterPermissions(String permission) {
    permissions.add(permission);
    return "Permission " + permission + "ajouté";
  }
}
