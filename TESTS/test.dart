// ignore_for_file: unused_local_variable

import 'package:files_handler/models/fichier.dart';

void main() async {
  Status statut = Status.actif;

  print('Le statut est : ${statut.value}'); // Output: Le statut est : Actif

  // Exemple de switch sur l'énumération
  switch (statut) {
    case Status.actif:
      print('Le statut est actif.');
      break;
    case Status.inactif:
      print('Le statut est inactif.');
      break;
    case Status.suspendu:
      print('Le statut est suspendu.');
      break;
  }
}

enum Status {
  actif('Actif'),
  inactif('Inactif'),
  suspendu('Suspendu');

  // Propriété pour stocker la chaîne de caractères
  final String description;

  // Constructeur pour assigner la chaîne
  const Status(this.description);

  // Optionnel : méthode pour récupérer la chaîne associée
  String get value => description;
}
