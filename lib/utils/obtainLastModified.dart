import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';


Future<DateTime> obtenirDateDerniereModification(String filePath) async {
    try {
      final file = File(filePath);
      final lastModified = await file.lastModified();
      return lastModified;
    } catch (e) {
      print(
          'Erreur lors de la récupération de la date de la dernière modification: $e');
      throw e;
    }
  }
