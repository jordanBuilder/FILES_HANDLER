import 'dart:io';

import 'package:files_handler/models/repertoire.dart';
import 'package:files_handler/utils/deplacer.dart';
import 'package:files_handler/utils/dezipper.dart';

class EventHandlers {
  Future<void> handleCreateEvent(
    FileSystemCreateEvent event,
    Repertoire? remoteRepertoire,
    Repertoire? zipRepertoire,
    Repertoire? localRepertoire,
  ) async {
    // FileSystemEntityType type = FileSystemEntity.typeSync(event.path);
    try {
      if (File(event.path).existsSync() &&
          File(event.path).parent.toString().contains("REMOTE") &&
          !File(event.path).parent.toString().contains("LOCALE") &&
          event.path.endsWith('.zip')) {
        print(
            "Evenement de création détecté dans REMOTE: ${event.runtimeType}, vers le chemin: ${event.path}");
        String extractedPath = await dezipper(event.path, zipRepertoire!.path);
        await deplacer(extractedPath, localRepertoire!.path);
      }
    } catch (e) {
      print(e);
    }

    // if (remoteRepertoire != null) {
    //   print("Création détectée dans REMOTE");
    //   // Logique spécifique à REMOTE
    // } else if (zipRepertoire != null) {
    //   print("Création détectée dans ZIP");
    //   // Logique spécifique à ZIP
    // } else if (localRepertoire != null) {
    //   print("Création détectée dans LOCALE");
    //   // Logique spécifique à LOCALE
    // } else {
    //   print("Répertoire non pris en charge pour la création");
    // }
  }

  Future<void> handleModifyEvent(
    FileSystemModifyEvent event,
    Repertoire? repertoireSurveille,
    Repertoire? zipRepertoire,
    Repertoire? destinationRepertoire,
  ) async {
    print("Modification détectée : ${event.path}");
  }

  void handleDeleteEvent(
    FileSystemDeleteEvent event,
    Repertoire? remoteRepertoire,
    Repertoire? localRepertoire,
  ) {
    print("Suppression détectée : ${event.path}");
  }

  Future<void> handleMoveEvent(FileSystemMoveEvent event) async {
    print("Déplacement détecté : ${event.path}");
  }
}
