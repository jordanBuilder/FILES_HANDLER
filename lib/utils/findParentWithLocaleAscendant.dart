// ignore_for_file: file_names, depend_on_referenced_packages
import 'dart:io';
import 'package:path/path.dart';


Directory? trouverParentAvecAscendantLOCALE(String filePath) {
    Directory currentDir = Directory(filePath);
    while (currentDir.parent.existsSync()) {
      final parentDir = currentDir.parent;
      if (basename(parentDir.path) == "LOCALE") {
        return currentDir;
      }
      currentDir = parentDir;
    }
    return null;
  }