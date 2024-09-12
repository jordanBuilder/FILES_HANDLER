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

  //Methode pour zipper un fichier
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  Future<String> zipper(String filePath, String destinationPath) async {
    try {
      final file = File(filePath);
      final encoder = ZipFileEncoder();
      final archive = Archive();

      if (file.existsSync()) {
        final fileData = file.readAsBytesSync();
        archive.addFile(
            ArchiveFile(file.path.split('/').last, fileData.length, fileData));

        final zipFile = File(destinationPath);

        if (zipFile.existsSync()) {
          zipFile.deleteSync();
        }

        encoder.create(destinationPath);
        encoder.addFile(file);
        encoder.close();

        return 'Zippage du fichier terminé.';
      } else {
        return 'Le fichier spécifié n\'existe pas.';
      }
    } catch (e) {
      print('Erreur lors du zippage: $e');
      throw e;
    }
  }

// Assurez-vous d'avoir ce package pour la fonction join

  Future<String> dezipper(String zipPath, String destinationPath) async {
    try {
      // Lecture de l'archive
      final archiveBytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(archiveBytes);

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
      }

      return 'Dézippage du fichier terminé.';
    } catch (e) {
      print('Erreur lors du dézippage: $e');
      // Relancer l'erreur pour que la méthode retourne une erreur
      throw e;
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

  Stream<FileSystemEvent> surveiller() {
    final dir = Directory(path);
    return dir.watch();
  }

  final Set<String> fichiersEnCoursDeTraitement = {};
final Queue<FileSystemEvent> evenementsEnAttente = Queue<FileSystemEvent>();


  void ecouterEvenements(
      Repertoire? zipRepertoire, Repertoire? destinationRepertoire) {
    try {
      final stream = Directory(path).watch();
      changerStatut(RepertoireStatus.surveille);

      stream.listen(
        (FileSystemEvent event) {
          try {
            switch (event.runtimeType) {
              case FileSystemCreateEvent:
                _traiterCreation(
                  event as FileSystemCreateEvent,
                  zipRepertoire,
                  destinationRepertoire,
                );
                break;
              case FileSystemModifyEvent:
                _traiterModification(
                  event as FileSystemModifyEvent,
                  zipRepertoire,
                  destinationRepertoire,
                );
                break;
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

  void _traiterCreation(FileSystemCreateEvent event, Repertoire? zipRepertoire,
      Repertoire? destinationRepertoire) {
    print('Création détectée: ${event.path}');

    // Vérifie si l'événement concerne un fichier ZIP
    if (event.path.endsWith('.zip')) {
      if (type == 'dossier' && name == 'REMOTE') {
        if (zipRepertoire != null) {
          copier(event.path, zipRepertoire.path);
        }
      }
      // }else if(type == "dossier" && name == "ZIP"){
      //   if(destinationRepertoire != null){
      //     dezipper(event.path, zipRepertoire!.path)
      //     .then((result){
      //       deplacer(event.path, destinationRepertoire.path);
      //     }).catchError((error){
      //       print("Erreur lors de la decompression du fichier ZIP: $error");
      //     });
      //   }
      // }
    }
  }

  void _traiterModification(FileSystemModifyEvent event,
      Repertoire? zipRepertoire, Repertoire? destinationRepertoire) {
    print('Modification détectée: ${event.path}');

    Future.delayed(Duration(seconds: 2), () {
      if (type == "dossier" && name == "ZIP") {
        if (destinationRepertoire != null) {
          final file = File(event.path);
          if (file.existsSync()) {
            dezipper(event.path, zipRepertoire!.path).then((result) {
              deplacer(event.path, destinationRepertoire.path);
            }).catchError((error) {
              print("Erreur lors de la decompression du fichier ZIP: $error");
            });
          } else {
            print("Le fichier ZIP n'existe pas: ${event.path}");
          }
        }
      }
    });
    // Ajouter une logique pour traiter les modifications
  }

  void _traiterSuppression(FileSystemDeleteEvent event) {
    print('Suppression détectée: ${event.path}');
    // Ajouter une logique pour gérer les fichiers supprimés
  }

  String ajouterPermissions(String permission) {
    permissions.add(permission);
    return "Permission " + permission + "ajouté";
  }
}
