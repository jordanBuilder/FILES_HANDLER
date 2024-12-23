import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';

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