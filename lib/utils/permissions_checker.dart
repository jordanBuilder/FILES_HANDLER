import 'dart:io';

import 'package:files_handler/models/repertoire.dart';

class PermissionsChecker {
  List<RepertoirePermissions> permissions = [];

  ajouterPermissions(RepertoirePermissions permission) {
    permissions.add(permission);
  }

  Future<List<RepertoirePermissions>> verifierPermissions(String path) async {
    final userName = Platform.environment['USERNAME'];
    if (userName == null) {
      print("Impossible de récupérer le nom d'utilisateur.");
      return permissions;
    }
    final result = await Process.run('icacls', [path]);
    if (result.exitCode != 0) {
      print("Erreur lors de l'exécution de icacls: ${result.stderr}");
      return permissions;
    }
    final output = result.stdout as String;
    final lines = output.split('\n');
    print('Permissions de l\'utilisateur $userName sur le répertoire $path :');

    for (var line in lines) {
      if (line.contains(userName)) {
        if (line.contains('(R)') ||
            line.contains('(R,W)') ||
            line.contains('(F)')) {
          ajouterPermissions(RepertoirePermissions.readable);
        }
        if (line.contains('(W)') ||
            line.contains('(R,W)') ||
            line.contains('(F)')) {
          ajouterPermissions(RepertoirePermissions.writable);
        }
      }
    }
    if (permissions.isEmpty) {
      ajouterPermissions(RepertoirePermissions.unreadable);
      ajouterPermissions(RepertoirePermissions.unwritable);
    }
    permissions = permissions.toSet().toList();
    print(permissions);
    return permissions;
  }
}
