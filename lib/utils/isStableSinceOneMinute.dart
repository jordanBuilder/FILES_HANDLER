// ignore_for_file: file_names, avoid_print

import 'dart:io';
import 'dart:async';
import 'obtainLastModified.dart';

Future<bool> estStableDepuisUneMinute(String filePath) async {
    final file = File(filePath);
    const Duration attente = Duration(seconds: 10);

    try {
      // Vérifie si le fichier existe
      if (!file.existsSync()) {
        print("Le fichier n'existe pas: $filePath");
        return false;
      }
      DateTime? dateDerniereModification =
          await obtenirDateDerniereModification(filePath);

      // Attendre une minute
      await Future.delayed(attente);

      // Vérifier la date de la dernière modification après une minute
      DateTime? nouvelleDateDerniereModification =
          await obtenirDateDerniereModification(filePath);

      // Comparer les deux dates
      return dateDerniereModification!
          .isAtSameMomentAs(nouvelleDateDerniereModification!);
    } catch (e) {
      print(
          'Erreur lors de la récupération de la date de la dernière modification: $e');
      // Gérer l'erreur, éventuellement en essayant à nouveau ou en retournant false
      return false;
    }
  }