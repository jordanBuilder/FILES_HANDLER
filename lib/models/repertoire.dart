// ignore_for_file: avoid_print, unused_local_variable, unnecessary_brace_in_string_interps
import 'dart:io';
import 'dart:async';
import 'package:files_handler/utils/deplacer.dart';
import 'package:files_handler/utils/dezipper.dart';
import 'package:files_handler/utils/zipper.dart';
import 'package:path/path.dart';
import 'sub_directory_watcher.dart';
import '../utils/isStableSinceOneMinute.dart';

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

  void _changerStatut(RepertoireStatus nouveauStatut) {
    status = nouveauStatut;
  }

  //Methode pour zipper un fichier
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  String ajouterFichier(String filePath) {
    try {
      File(filePath).createSync();
      return "Fichier ajouté avec succés.";
    } catch (e) {
      return "Erreur lors de l\'ajout du fichier: $e";
    }
  }

  void ecouterEvenements(Repertoire? remoteRepertoire,
      Repertoire? zipRepertoire, Repertoire? localRepertoire) {
    try {
      final directory = Directory(path);
      final watcher = SubDirectoryWatcher(
          directory, remoteRepertoire, zipRepertoire, localRepertoire);
      watcher.watchRecursive();

// Démarrer l'écoute des événements une fois la surveillance en place
      final stream = directory.watch();
      _changerStatut(RepertoireStatus.surveille);

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
    }
  }

  Future<void> _traiterModification(FileSystemModifyEvent event,
      Repertoire? zipRepertoire, Repertoire? destinationRepertoire) async {
    print('Modification détectée: ${event.path}');
    if (type == "dossier" && name == "LOCALE") {
      if (zipRepertoire != null) {
        final file = File(event.path);
        if (file.existsSync()) {
          final parentDir = Directory(dirname(event.path));
          if (basename(parentDir.path) == "LOCALE") {
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

  bool _isWithinLocale(String filePath) {
    return filePath.contains('LOCALE');
  }
}
