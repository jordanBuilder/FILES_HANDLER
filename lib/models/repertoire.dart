// ignore_for_file: avoid_print, unused_local_variable, unnecessary_brace_in_string_interps

import 'dart:collection';
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

  Repertoire({required this.path}) {
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

  Future<DateTime> obtenirDateDerniereModification(String filePath) async {
    try {
      final file = File(filePath);
      final lastModified = await file.lastModified();
      return lastModified;
    } catch (e) {
      print(
          'Erreur lors de la récupération de la date de la dernière modification: $e');
      throw e;
    }
  }

  Future<bool> estStableDepuisUneMinute(String filePath) async {
    final file = File(filePath);
    const Duration attente = Duration(seconds: 18);

    try {
      // Vérifie si le fichier existe
      if (!file.existsSync()) {
        print("Le fichier n'existe pas: $filePath");
        return false;
      }
      DateTime dateDerniereModification =
          await obtenirDateDerniereModification(filePath);

      // Attendre une minute
      await Future.delayed(attente);

      // Vérifier la date de la dernière modification après une minute
      DateTime nouvelleDateDerniereModification =
          await obtenirDateDerniereModification(filePath);

      // Comparer les deux dates
      return dateDerniereModification
          .isAtSameMomentAs(nouvelleDateDerniereModification);
    } catch (e) {
      print(
          'Erreur lors de la récupération de la date de la dernière modification: $e');
      // Gérer l'erreur, éventuellement en essayant à nouveau ou en retournant false
      return false;
    }
  }

  //Methode pour zipper un fichier
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

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

  Future<String> copier(
      String sourceFilePath, String destinationDirPath) async {
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
      await sourceFile.copy(destinationFilePath);

      return "Fichier copié avec succès vers $destinationFilePath";
    } catch (e) {
      return "Erreur lors de la copie du fichier: $e";
    }
  }

  Future<String> deplacer(String sourcePath, String destinationDirPath) async {
    try {
      sourcePath = normalize(sourcePath);
      final entityType = FileSystemEntity.typeSync(sourcePath);

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
          print("Fichier existant supprimé: $destinationFilePath");
        }

        // Copier le fichier
        await sourceFile.copy(destinationFilePath);

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
        if (Directory(join(destinationFolderPath, dirName)).existsSync()) {
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

  copyDirectory(Directory source, Directory destination) =>
      source.listSync(recursive: false).forEach((var entity) {
        if (entity is Directory) {
          var newDirectory =
              Directory(join(destination.absolute.path, basename(entity.path)));
          print("Nouveau dossier à créer:  $newDirectory");
          newDirectory.createSync();
          copyDirectory(entity.absolute, newDirectory);
        } else if (entity is File) {
          entity.copySync(join(destination.path, basename(entity.path)));
        }
      });

  String ajouterFichier(String filePath) {
    try {
      File(filePath).createSync();
      return "Fichier ajouté avec succés.";
    } catch (e) {
      return "Erreur lors de l\'ajout du fichier: $e";
    }
  }

  Stream<FileSystemEvent> surveiller() {
    final dir = Directory(path);
    return dir.watch();
  }

  void ecouterEvenements(Repertoire? remoteRepertoire,
      Repertoire? zipRepertoire, Repertoire? localRepertoire) {
    try {
      final stream = Directory(path).watch();
      changerStatut(RepertoireStatus.surveille);

      stream.listen(
        (FileSystemEvent event) {
          try {
            final sourceRepertoire = this;
            switch (event.runtimeType) {
              case FileSystemCreateEvent:
                if (sourceRepertoire == remoteRepertoire) {
                  print('Création détectée dans REMOTE, destination: ZIP');
                  _traiterCreation(
                    event as FileSystemCreateEvent,
                    zipRepertoire, // ZIP comme destination
                    localRepertoire,
                  );
                } else if (sourceRepertoire == localRepertoire) {
                  print('Création détectée dans LOCALE, destination: ZIP');
                  _traiterCreation(
                    event as FileSystemCreateEvent,
                    zipRepertoire, // ZIP comme destination
                    remoteRepertoire,
                  );
                }
                break;
              case FileSystemModifyEvent:
                if (sourceRepertoire == localRepertoire) {
                  print('Modification détéctée dans LOCALE, destination: ZIP');
                  _traiterModification(
                    event as FileSystemModifyEvent,
                    zipRepertoire, // ZIP comme destination
                    remoteRepertoire,
                  );
                }

              //   break;
              // case FileSystemDeleteEvent:
              //   _traiterSuppression(event as FileSystemDeleteEvent);
              //   break;
              default:
                // Gérer d'autres types d'événements si nécessaire
                print('Événement non géré: ${event.runtimeType}');
                break;
            }
          } catch (e) {
            // Gérer les erreurs spécifiques aux opérations d'événements
            print('Erreur lors du traitement de l\'événement: $e');
          }
        },
        onError: (error) {
          // Gérer les erreurs liées au flux de surveillance
          print('Erreur de surveillance du répertoire: $error');
        },
      );
    } catch (e) {
      // Gérer les erreurs liées à la création du flux de surveillance
      print('Erreur lors de la création du flux de surveillance: $e');
    }
  }

  Future<void> _traiterCreation(FileSystemCreateEvent event,
      Repertoire? zipRepertoire, Repertoire? destinationRepertoire) async {
    print('Création détectée: ${event.path}');

    // Vérifie si l'événement concerne un fichier ZIP
    if (event.path.endsWith('.zip')) {
      if (type == 'dossier' && name == 'REMOTE') {
        if (zipRepertoire != null) {
          if (File(event.path).existsSync()) {
            // ignore: non_constant_identifier_names
            String repertoire_path =
                await dezipper(event.path, zipRepertoire.path);
            if (destinationRepertoire != null) {
              print("Deplacement vers ${destinationRepertoire.path}");
              await deplacer(repertoire_path, destinationRepertoire.path);
            }
          } else {
            // ignore: avoid_print
            print(
                "Le fichier ZIP n'existe pas ou est en cours d'écriture : ${event.path}");
          }
        }
      }
      // } else {
      //   if (type == "dossier" && name == "ZIP") {
      //     if (destinationRepertoire != null) {
      //       await deplacer(event.path, destinationRepertoire.path);
      //     }
      //   }
      // }
    }
  }

  Future<void> _traiterModification(FileSystemModifyEvent event,
      Repertoire? zipRepertoire, Repertoire? destinationRepertoire) async {
    print('Modification détectée: ${event.path}');
    if (type == "dossier" && name == "LOCALE") {
      if (zipRepertoire != null) {
        final file = File(event.path);
        if (file.existsSync()) {
          try {
            if (await estStableDepuisUneMinute(event.path)) {
              String fileToZipWithZipExtension =
                  extractFileNameFromPath(event.path);

              print(
                  "Sur le point de zipper: ${event.path} vers ${join(zipRepertoire.path, fileToZipWithZipExtension)}");

              String zipFilePath = await zipper(event.path,
                  join(zipRepertoire.path, fileToZipWithZipExtension));

              if (zipFilePath.endsWith('.zip')) {
                print('Zippage terminé, fichier créé à: $zipFilePath');
                print("************** ****************** *****************");
                await deplacer(zipFilePath, destinationRepertoire!.path);
                print("************** ****************** *****************");
              } else {
                print('Erreur lors du zippage: $zipFilePath');
              }
            } else {
              print(
                  'Le fichier a été modifié pendant l\'attente. Processus de zip avorté');
            }
          } catch (e) {
            print('Erreur lors du traitement du fichier: $e');
          }
        } else {
          print("Le fichier ZIP n'existe pas: ${event.path}");
        }
      }
    }
  }

  void _traiterSuppression(FileSystemDeleteEvent event) {
    print('Suppression détectée: ${event.path}');
    // Ajouter une logique pour gérer les fichiers supprimés
  }

  String ajouterPermissions(String permission) {
    permissions.add(permission);
    return "Permission " + permission + "ajouté";
  }

  Future<void> _traiterMove(FileSystemMoveEvent event,
      Repertoire? zipRepertoire, Repertoire? destinationRepertoire) async {
    print('Déplacement détecté: ${event.path}');
  }

  String extractFileNameFromPath(String path) {
    String fileNameWithoutExtension = basenameWithoutExtension(path);
    String zipFileName = '$fileNameWithoutExtension.zip';
    return zipFileName;
  }
}
