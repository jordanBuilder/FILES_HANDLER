// ignore_for_file: file_names, avoid_print

import 'dart:io';
import 'dart:async';

Future<DateTime?> obtenirDateDerniereModification(String filePath) async {
  try {
    final file = File(filePath);

    // Vérifie si c'est un fichier temporaire (par exemple, avec une extension .tmp)
    if (file.path.endsWith('.tmp') || file.path.contains('~')) {
      print('Fichier temporaire détecté : ${file.path}');
      return null; // Retourne null ou une autre valeur si tu veux ignorer les fichiers temporaires
    }

    // Obtenir la date de la dernière modification
    final lastModified = await file.lastModified();
    return lastModified;
  } catch (e) {
    print('Erreur lors de la récupération de la date de la dernière modification: $e');
    return null;
  }
}
