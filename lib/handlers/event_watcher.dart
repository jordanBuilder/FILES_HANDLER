import 'dart:async';
import 'dart:io';
import 'package:files_handler/handlers/event_handler.dart';
import 'package:files_handler/models/repertoire.dart';

class EventWatcher {
  final Directory directory;
  final EventHandlers eventHandlers;
  final Repertoire zipRepertoire;
  final Repertoire remoteRepertoire;
  final Repertoire localeRepertoire;

  final Map<String, StreamSubscription<FileSystemEvent>> _subscriptions = {};

  EventWatcher(
    this.directory,
    this.eventHandlers,
    this.zipRepertoire,
    this.remoteRepertoire,
    this.localeRepertoire,
  );

  void startWatching() {
    // Déterminer quel répertoire est surveillé
    Repertoire currentRepertoire;
    if (directory.path == zipRepertoire.path) {
      currentRepertoire = zipRepertoire;
    } else if (directory.path == remoteRepertoire.path) {
      currentRepertoire = remoteRepertoire;
    } else if (directory.path == localeRepertoire.path) {
      currentRepertoire = localeRepertoire;
    } else {
      throw Exception("Répertoire inconnu : ${directory.path}");
    }
    _watchDirectory(directory);
  }

  void _watchDirectory(Directory dir) {
    final stream = dir.watch();

    // S'abonner au flux d'événements pour ce répertoire
    _subscriptions[dir.path] = stream.listen(
      (FileSystemEvent event) {
        switch (event.runtimeType) {
          case FileSystemCreateEvent:
            if (event is FileSystemCreateEvent) {
              _handleCreate(event);
            }
            break;
          case FileSystemModifyEvent:
            if (event is FileSystemModifyEvent) {
              eventHandlers.handleModifyEvent(event, null, null, null);
            }
            break;
          case FileSystemDeleteEvent:
            if (event is FileSystemDeleteEvent) {
              eventHandlers.handleDeleteEvent(event, null, null);
            }
            break;
          case FileSystemMoveEvent:
            if (event is FileSystemMoveEvent) {
              eventHandlers.handleMoveEvent(event);
            }
            break;
          default:
            print('Événement non géré : ${event.runtimeType}');
            break;
        }
      },
      onError: (error) {
        print('Erreur de surveillance sur ${dir.path}: $error');
      },
    );
  }

  void _watchSubdirectories(Directory dir) {
    for (var entity in dir.listSync(recursive: false)) {
      if (entity is Directory) {
        _watchDirectory(entity);
        _watchSubdirectories(entity); // Récursion pour les sous-répertoires
      }
    }
  }

  void _handleCreate(FileSystemCreateEvent event) {
    final newEntity = FileSystemEntity.typeSync(event.path);
    if (newEntity == FileSystemEntityType.directory) {
      // Surveiller les nouveaux sous-répertoires créés
      _watchDirectory(Directory(event.path));
      _watchSubdirectories(Directory(event.path));
    }

    // Passer l'événement à l'EventHandler
    eventHandlers.handleCreateEvent(
        event, remoteRepertoire, zipRepertoire, localeRepertoire);
  }

  void stopWatching() {
    // Annuler toutes les abonnements
    _subscriptions.values.forEach((subscription) => subscription.cancel());
    _subscriptions.clear();
    print("Surveillance arrêtée pour le répertoire : ${directory.path}");
  }
}
