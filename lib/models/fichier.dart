
import 'repertoire.dart';

class Fichier extends Repertoire {
  Fichier({
    required String path,
    List<RepertoirePermissions> permissions = const [], // Par défaut, liste vide
  }) : super(path: path) {
    this.permissions = permissions;
    initializeProperties(); // Initialise les propriétés héritées
  }

  @override
  void initializeProperties() {
    super.initializeProperties(); // Appel à la méthode de la classe parent
    type = 'fichier'; // Le type pour un fichier est toujours 'fichier'
  }
}
