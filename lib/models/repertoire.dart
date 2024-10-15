// ignore_for_file: avoid_print, unused_local_variable, unnecessary_brace_in_string_interps, type_literal_in_constant_pattern, unused_element
import 'dart:io';
import 'dart:async';
import 'package:files_handler/utils/deplacer.dart';
import 'package:files_handler/utils/dezipper.dart';
import 'package:files_handler/utils/zipper.dart';
import 'package:path/path.dart';
import 'sub_directory_watcher.dart';
import '../utils/isStableSinceOneMinute.dart';
import '../screens/windows_popup.dart'; // La page des détails

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

  Future<void> verifierPermissions(String path) async {
    final userName = Platform.environment['USERNAME'];
    if (userName == null) {
      print("Impossible de récupérer le nom d'utilisateur.");
      return;
    }
    final result = await Process.run('icacls', [path]);
    if (result.exitCode != 0) {
      print("Erreur lors de l'exécution de icacls: ${result.stderr}");
      return;
    }
    final output = result.stdout as String;
    final lines = output.split('\n');
    print('Permissions de l\'utilisateur $userName sur le répertoire $path :');

    for (var line in lines) {
      if (line.contains(userName)) {
        if (line.contains('(R)') ||
            line.contains('(R,W)') ||
            line.contains('(F)')) {
          ajouterPermissions(RepertoirePermissions.readable);
        }
        if (line.contains('(W)') ||
            line.contains('(R,W)') ||
            line.contains('(F)')) {
          ajouterPermissions(RepertoirePermissions.writable);
        }
      }
    }

    if (permissions.isEmpty) {
      ajouterPermissions(RepertoirePermissions.unreadable);
      ajouterPermissions(RepertoirePermissions.unwritable);
    }
    permissions = permissions.toSet().toList();
    print(permissions);
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
      return "Erreur lors de l'ajout du fichier: $e";
    }
  }

  void ajouterPermissions(RepertoirePermissions permission) {
    permissions =
        List.from(permissions); // S'assurer que la liste est modifiable
    permissions.add(permission);
  }

  void ecouterEvenements(Repertoire? remoteRepertoire,
      Repertoire? zipRepertoire, Repertoire? localRepertoire) {
    final watcher =
        SubDirectoryWatcher(remoteRepertoire, zipRepertoire, localRepertoire);
    watcher.watchRecursive();

    void surveillerRepertoire(
        Directory directory, Repertoire repertoireSurveille) {
      try {
        final stream = directory.watch();
        _changerStatut(RepertoireStatus.surveille);

        stream.listen(
          (FileSystemEvent event) {
            try {
              final sourceRepertoire = repertoireSurveille;
              switch (event.runtimeType) {
                case FileSystemCreateEvent:
                  if (sourceRepertoire == remoteRepertoire) {
                    if (hasReadableAndWritable(permissions)) {
                      print(
                          "Événement détecté dans REMOTE : ${event.runtimeType}, chemin : ${event.path}");

                      _hanldeCreationEvent(
                        event as FileSystemCreateEvent,
                        repertoireSurveille,
                        zipRepertoire, // ZIP comme destination
                        localRepertoire,
                      );
                    }
                  } else if (sourceRepertoire == localRepertoire) {
                    if (hasReadableAndWritable(localRepertoire!.permissions)) {
                      print(
                          "Événement détecté dans LOCALE : ${event.runtimeType}, chemin : ${event.path}");
                      surveillerRepertoire(
                          Directory(event.path), localRepertoire);
                    }
                  }

                  break;
                case FileSystemModifyEvent:
                  if (sourceRepertoire == localRepertoire) {
                    if (hasWritable(localRepertoire!.permissions)) {
                      _hanldeModificationEvent(
                        event as FileSystemModifyEvent,
                        repertoireSurveille,
                        zipRepertoire,
                        remoteRepertoire,
                      );
                    }

                    if (sourceRepertoire == remoteRepertoire) {
                      _hanldeModificationEvent(
                        event as FileSystemModifyEvent,
                        repertoireSurveille,
                        zipRepertoire,
                        localRepertoire,
                      );
                    }
                  }
                  break;

                case FileSystemDeleteEvent:
                  if (hasWritable(permissions)) {
                    _hanldeDeletionEvent(event as FileSystemDeleteEvent,
                        remoteRepertoire, localRepertoire);
                  }
                  break;
                case FileSystemMoveEvent:
                  if (hasWritable(permissions)) {
                    _hanldeMoveEvent(event as FileSystemMoveEvent);
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
        print('Erreur lors de la création du flux de surveillance: $e');
      }
    }

    if (remoteRepertoire != null) {
      surveillerRepertoire(Directory(remoteRepertoire.path), remoteRepertoire);
    }

    if (localRepertoire != null) {
      surveillerRepertoire(Directory(localRepertoire.path), localRepertoire);
    }
  }

  Future<void> _hanldeCreationEvent(
      FileSystemCreateEvent event,
      Repertoire? repertoireSurveile,
      Repertoire? zipRepertoire,
      Repertoire? destinationRepertoire) async {
    // Vérifie si l'événement concerne un fichier ZIP
    if (event.path.endsWith('.zip')) {
      if (type == 'dossier' && repertoireSurveile!.name == "REMOTE") {
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

  Future<void> _hanldeModificationEvent(
      FileSystemModifyEvent event,
      Repertoire? repertoireSurveille,
      Repertoire? zipRepertoire,
      Repertoire? destinationRepertoire) async {
    if (type == "dossier" && repertoireSurveille!.name == "LOCALE") {
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
          // print(
          //     "Le fichier ZIP n'existe pas: ${event.path}, ou est en cours de copie ou soit c'est un fichier test_permissions pour verifier les permissions des REPERTOIRES");
        }
      }
    }
  }

  void _hanldeDeletionEvent(FileSystemDeleteEvent event, final remoteRepertoire,
      final localRepertoire) {
    if (type == "dossier" && event.path.contains("REMOTE")) {
      _deleteFromLocalDirectory(event.path, remoteRepertoire, localRepertoire);
    }
  }

  Future<void> _hanldeMoveEvent(FileSystemMoveEvent event) async {
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

  void _deleteFromLocalDirectory(
      String path, final remoteRepertoire, final localRepertoire) async {
    try {
      final localDir = Directory(localRepertoire.path);
      final remoteDir = Directory(remoteRepertoire.path);
      final List<FileSystemEntity> entities = await localDir.list().toList();

      final eventBaseName = getBaseName(path);
      // const Duration attente = Duration(seconds: 10);

      for (var entity in entities) {
        final entityBaseName = getBaseName(entity.path);
        final findedInRemote = await findPathInDirectory(remoteDir, path);
        if ((entityBaseName == eventBaseName) && !findedInRemote) {
          if (entity is File) {
            try {
              WindowsPopup.showAutoCloseWarning(path);
               entity.deleteSync();

              print("Fichier supprimé: ${entity.path}");
            } catch (e) {
              if (e is FileSystemException && e.osError?.errorCode == 2) {
                // Error code 2 corresponds to "No such file or directory" on Windows
                print(
                    "Le fichier a été  supprimé par une action sur le bureau ou n'existe pas: ${entity.path}");
              } else {
                print("Erreur lors de la suppression du fichier: $e");
              }
            }
          } else if (entity is Directory) {
            try {
              WindowsPopup.showAutoCloseWarning(path);
              entity.deleteSync(recursive: true);
              
              print("Dossier supprimé: $path");
            } catch (e) {
              if (e is FileSystemException && e.osError?.errorCode == 2) {
                // Error code 2 corresponds to "No such file or directory" on Windows
                print(
                    "Le dossier a été supprimé par une action sur le bureau ou n'existe pas: ${entity.path}");
              } else {
                print("Erreur lors de la suppression du dossier! $e");
              }
            }
          }
        }
      }
    } catch (e) {
      print(
          "Erreur lors de la recherche du repertoire effacé, dans LocalRepertoire! $e");
    }
  }

  String getBaseName(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    return fileName.split('.').first;
  }

  Future<bool> findPathInDirectory(
      Directory directory, String pathToFind) async {
    try {
      await for (var entity in directory.list(recursive: true)) {
        if (entity.path == pathToFind) {
          print('Trouvé : $pathToFind');
          return true;
        }
      }
    } catch (e) {
      print('Erreur: $e');
    }
    return false;
  }
}
