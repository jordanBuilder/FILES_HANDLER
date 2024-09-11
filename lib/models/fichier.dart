import 'dart:io';
import 'dart:async';
import 'package:path/path.dart';
import 'package:archive/archive_io.dart';

import 'repertoire.dart';

class Fichier extends Repertoire {
  Fichier(
      {required String name,
      required String path,
      required int size,
      required bool status,
      required List<String> permissions})
      : super(
            name: name,
            path: path,
            size: size,
            status: status,
            permissions: permissions);
}


