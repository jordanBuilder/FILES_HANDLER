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

enum RepertoirePermissions {
  readable('readable'),
  unreadable('unreadable'),
  writable('writable'),
  unwritable('unwritable');

  final String description;

  const RepertoirePermissions(this.description);

  String get value => description;
}

class Repertoire {
  late String name;
  late String path;
  late Map<String, int> size;
  late RepertoireStatus status;
  late String type;
  late List<RepertoirePermissions> permissions = [];

  Repertoire({required this.path}) {
    status = RepertoireStatus.nonSurveille;
    initializeProperties();
  }

  void initializeProperties() async {
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
    size = await _getDirectorySize(path);

    verifierPermissions(path);
  }

  Future<Map<String, int>> _getDirectorySize(String dirPath) async {
    int fileNum = 0;
    int directoryNum = 0;
    int totalSize = 0;
    var dir = Directory(dirPath);
    try {
      if (dir.existsSync()) {
        dir
            .listSync(recursive: false, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            fileNum++;
            totalSize += entity.lengthSync();
          } else if (entity is Directory) {
            directoryNum++;
          }
        });
      }
    } catch (e) {
      print(e.toString());
    }
    return {
      "DirectoryNum": directoryNum,
      "fileNum": fileNum,
      "totalSize": totalSize
    };
  }

  void verifierPermissions(String path) {
    final entity = FileSystemEntity.typeSync(path);

    if (entity == FileSystemEntityType.notFound) {
      print("Le Chemin spécifié n'existe pas !");
      return;
    }

    if (entity == FileSystemEntityType.file) {
      final file = File(path);

      try {
        file.readAsBytesSync();
        ajouterPermissions(RepertoirePermissions.readable);
      } catch (e) {
        print("Le fichier n'est pas lisible : $e");
        ajouterPermissions(RepertoirePermissions.unreadable);
      }

      try {
        file.writeAsStringSync(" ");
        ajouterPermissions(RepertoirePermissions.writable);
      } catch (e) {
        print("Le fichier n'est pas écrivable: $e");
        ajouterPermissions(RepertoirePermissions.unwritable);
      }
    } else if (entity == FileSystemEntityType.directory) {
      final directory = Directory(path);
      try {
        directory.listSync();
        ajouterPermissions(RepertoirePermissions.readable);
      } catch (e) {
        print("Le dossier n'est pas accessible: $e");
        ajouterPermissions(RepertoirePermissions.unreadable);
      }

      try {
        final testFile = File('${directory.path}/test_permissions.txt');
        testFile.writeAsStringSync('Test');
        ajouterPermissions(RepertoirePermissions.writable);
        testFile.deleteSync();
      } catch (e) {
        print("Le dossier n'est pas écrivable");
        ajouterPermissions(RepertoirePermissions.unwritable);
      }
    } else {
      print("Le chemin spécifié n'est ni un fichier ni un repertoire");
    }
  }

  bool hasReadableAndWritable(List<RepertoirePermissions> permissions) {
    return this.permissions.contains(RepertoirePermissions.readable) &&
        this.permissions.contains(RepertoirePermissions.writable);
  }

  bool hasReadable(List<RepertoirePermissions> permissions) {
    return this.permissions.contains(RepertoirePermissions.readable);
  }

  bool hasWritable(List<RepertoirePermissions> permissions) {
    return this.permissions.contains(RepertoirePermissions.writable);
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

  void ajouterPermissions(RepertoirePermissions permission) {
    permissions =
        List.from(permissions); // S'assurer que la liste est modifiable
    permissions.add(permission);
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
                if (hasWritable(permissions)) {
                  if (sourceRepertoire == remoteRepertoire) {
                    print('Création détectée dans REMOTE, destination: ZIP');
                    _traiterCreation(
                      event as FileSystemCreateEvent,
                      zipRepertoire, // ZIP comme destination
                      localRepertoire,
                    );
                  } else if (sourceRepertoire == localRepertoire) {
                    print(
                        '*******Création détectée dans LOCALE*********************');
                    _traiterCreation(
                      event as FileSystemCreateEvent,
                      zipRepertoire, // ZIP comme destination
                      remoteRepertoire,
                    );
                  }
                }

                break;
              case FileSystemModifyEvent:
                if (hasWritable(permissions)) {
                  if (sourceRepertoire == localRepertoire) {
                    print(
                        "Modification d'un fichier enfant direct, détéctée dans LOCALE, destination: ZIP");
                    _traiterModification(
                      event as FileSystemModifyEvent,
                      zipRepertoire, // ZIP comme destination
                      remoteRepertoire,
                    );
                  }

                  if (sourceRepertoire == remoteRepertoire) {
                    print('Modification détéctée dans REMOTE');
                    _traiterModification(
                      event as FileSystemModifyEvent,
                      zipRepertoire, // ZIP comme destination
                      localRepertoire,
                    );
                  }
                }
                break;

              case FileSystemDeleteEvent:
                if (hasWritable(permissions)) {
                  _traiterSuppression(event as FileSystemDeleteEvent);
                }
                break;
              case FileSystemMoveEvent:
                if (hasWritable(permissions)) {
                  _traiterMove(event as FileSystemMoveEvent);
                }
                break;
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

  Future<void> _traiterMove(FileSystemMoveEvent event) async {
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
