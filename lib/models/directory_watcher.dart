// ignore_for_file: avoid_print

import 'dart:io';

class DirectoryWatcher {
  final Directory directory;

  DirectoryWatcher(this.directory);

  // Fonction récursive pour surveiller un répertoire et ses sous-répertoires
  void watchRecursive() {
    // Surveiller le répertoire actuel
    _watchDirectory(directory);

    // Parcourir les sous-répertoires
    directory.list(recursive: true).listen((FileSystemEntity entity) {
      if (entity is Directory) {
        _watchDirectory(entity);
      }
    });
  }

  // Fonction pour surveiller un répertoire spécifique
  void _watchDirectory(Directory dir) {
    dir.watch().listen((event) {
      switch (event.type) {
        case FileSystemEvent.create:
          print('Création détectée dans ${event.path}');
          break;
        case FileSystemEvent.modify:
          print('Modification détectée dans ${event.path}');
          break;
        case FileSystemEvent.delete:
          print('Suppression détectée dans ${event.path}');
          break;
        case FileSystemEvent.move:
          print('Déplacement détecté dans ${event.path}');
          break;
      }
    }, onError: (error) {
      print('Erreur dans la surveillance de $dir: $error');
    });
  }
}


