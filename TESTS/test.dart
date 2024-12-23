// ignore_for_file: avoid_print

import 'dart:io';

void checkDirectoryPermissions(String directoryPath) {
  // Exécutez la commande icacls
  Process.run('icacls', [directoryPath]).then((result) {
    // Vérifiez le code de sortie
    if (result.exitCode == 0) {
      final output = result.stdout as String;
      // Analysez la sortie pour trouver les droits spécifiques de l'utilisateur
      final lines = output.split('\n');
      bool readPermission = false;
      bool writePermission = false;

      for (var line in lines) {
        if (line.contains('Lenovo')) { // Remplacez 'Lenovo' par le nom de l'utilisateur actuel
          if (line.contains('(R)') || line.contains('(R,W)') || line.contains('(F)')) {
            readPermission = true; // Lecture
          }
          if (line.contains('(W)') || line.contains('(R,W)') || line.contains('(F)')) {
            writePermission = true; // Écriture
          }
        }
      }

      // Affichage des résultats
      print('Permissions pour le répertoire $directoryPath:');
      if (readPermission && writePermission) {
        print('Droits: Lecture et Écriture');
      } else if (readPermission) {
        print('Droits: Lecture seulement');
      } else if (writePermission) {
        print('Droits: Écriture seulement');
      } else {
        print('Aucun droit d\'accès');
      }
    } else {
      print('Erreur lors de l\'exécution de icacls: ${result.stderr}');
    }
  });
}

void main() {
  checkDirectoryPermissions(r"C:\Users\Lenovo\Desktop\REMOTE");
}
