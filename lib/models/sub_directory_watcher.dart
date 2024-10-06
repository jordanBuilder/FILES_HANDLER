// ignore_for_file: avoid_print, unrelated_type_equality_checks

import 'dart:io';
import 'dart:async';
import 'package:files_handler/utils/deplacer.dart';
import 'package:files_handler/utils/zipper.dart';
import 'package:path/path.dart';

import 'package:files_handler/models/repertoire.dart';
import 'package:files_handler/utils/findParentWithLocaleAscendant.dart';
import 'package:files_handler/utils/isStableSinceOneMinute.dart';

class SubDirectoryWatcher {
  final List<StreamSubscription<FileSystemEvent>> _subscriptions = [];
  final Repertoire? remoteRepertoire;
  final Repertoire? zipRepertoire;
  final Repertoire? localRepertoire;

  // Ajoute un StreamController pour envoyer des événements
  final StreamController<String> _eventStreamController =
      StreamController<String>.broadcast();

  SubDirectoryWatcher(this.remoteRepertoire, this.zipRepertoire,
      this.localRepertoire);

  // Fonction récursive pour surveiller un répertoire et ses sous-répertoires
  void watchRecursive() {
    // Surveiller le répertoire actuel
    _watchSubDirectory(Directory(remoteRepertoire!.path));

    // Parcourir les sous-répertoires de manière récursive
    Directory(remoteRepertoire!.path).list(recursive: true).listen((FileSystemEntity entity) {
      if (entity is Directory) {
        _watchSubDirectory(entity);
      }
    });
    Directory(localRepertoire!.path).list(recursive: true).listen((FileSystemEntity entity) {
      if (entity is Directory) {
        _watchSubDirectory(entity);
      }
    });
  }

  // Fonction pour surveiller un répertoire spécifique
  void _watchSubDirectory(Directory dir) {
    try {
      final subscription = dir.watch().listen(
        (event) async {
          String message = '';
          switch (event.type) {
            case FileSystemEvent.create:
              final entity = FileSystemEntity.typeSync(event.path) ==
                      FileSystemEntityType.directory
                  ? Directory(event.path)
                  : File(event.path);
              if (FileSystemEntity.typeSync(event.path) ==
                      FileSystemEntityType.file &&
                  !entity.parent.path.endsWith("LOCALE")) {
                message =
                    'Création d\'un sous repertoire détectée dans ${event.path}';
              }
              break;

            case FileSystemEvent.modify:
            
              final entity = FileSystemEntity.typeSync(event.path) ==
                      FileSystemEntityType.directory
                  ? Directory(event.path)
                  : File(event.path);
              if (FileSystemEntity.typeSync(event.path) ==
                      FileSystemEntityType.file &&
                  !entity.parent.path.endsWith("LOCALE")) {
                message =
                    "Modification d'un sous-répertoire détectée dans ${event.path}";
                print(
                    "Modification d'un sous-répertoire détectée dans ${event.path}");
                if (event.path.contains("LOCALE")) {
                  Directory? parentAvecLocale =
                      trouverParentAvecAscendantLOCALE(event.path);
                  if (parentAvecLocale != null) {
                    message =
                        "Dossier parent trouvé avec ascendant 'LOCALE': ${parentAvecLocale.path}";
                    print(
                        "Dossier parent trouvé avec ascendant 'LOCALE': ${parentAvecLocale.path}");
                    if (await estStableDepuisUneMinute(event.path)) {
                      // Nom du fichier ZIP
                      String dirToZipWithZipExtension =
                          "${basename(parentAvecLocale.path)}.zip";
                      String zipDestinationPath =
                          join(zipRepertoire!.path, dirToZipWithZipExtension);

                      message =
                          "Sur le point de zipper le dossier: ${parentAvecLocale.path} vers $zipDestinationPath";

                      print(
                          "Sur le point de zipper le dossier: ${parentAvecLocale.path} vers $zipDestinationPath");

                      // Zipper le dossier
                      String zipFilePath = await zipper(
                          parentAvecLocale.path, zipDestinationPath);

                      if (zipFilePath.endsWith('.zip')) {
                        message =
                            'Zippage du dossier terminé, dossier créé à: $zipFilePath';
                        print(
                            'Zippage du dossier terminé, dossier créé à: $zipFilePath');

                        // Déplacer le fichier ZIP vers le répertoire de destination
                        await deplacer(zipFilePath, remoteRepertoire!.path);
                      } else {
                        message = 'Erreur lors du zippage: $zipFilePath';
                        print('Erreur lors du zippage: $zipFilePath');
                      }
                    } else {
                      message =
                          'Le fichier a été modifié pendant l\'attente. Processus de zip avorté';
                      print(
                          'Le fichier a été modifié pendant l\'attente. Processus de zip avorté');
                    }
                  }
                }
              }

              break;
            case FileSystemEvent.delete:
              break;
            case FileSystemEvent.move:
              break;
          }
          _eventStreamController.add(message);
        },
        onError: (error) {
          _eventStreamController
              .add('Erreur dans la surveillance de $dir: $error');
        },
      );

      // Ajouter la souscription à la liste pour pouvoir l'annuler si nécessaire
      _subscriptions.add(subscription);
    } catch (e) {
      _eventStreamController.add('Erreur lors de la surveillance de $dir: $e');
    }
  }

  // Fonction pour annuler toutes les souscriptions de surveillance
  void cancelAll() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _eventStreamController.close(); // Fermer le StreamController
    print('Surveillance annulée pour tous les répertoires.');
  }

  // Exposer le StreamController pour que d'autres parties de l'application puissent écouter
  Stream<String> get eventStream => _eventStreamController.stream;
}
