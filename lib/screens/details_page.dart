// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import '../models/repertoire.dart';

class DetailsPage extends StatefulWidget {
  final Repertoire remoteRepertoire;
  final Repertoire zipRepertoire;
  final Repertoire localRepertoire;

  const DetailsPage({
    Key? key,
    required this.remoteRepertoire,
    required this.zipRepertoire,
    required this.localRepertoire,
  }) : super(key: key);

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Repertoire? selectedRepertoire;
  StreamController<String>? _eventStreamController;
  late StreamSubscription<String> _eventSubscription;
  String eventMessages = '';
  final _scaleMap = <String, bool>{};
  @override
  void initState() {
    super.initState();

    _eventStreamController = StreamController<String>.broadcast();
    _eventSubscription = _eventStreamController!.stream.listen((message) {
      // Afficher un SnackBar pour chaque événement reçu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 3),
        ),
      );
    });

    // Démarrer la surveillance des répertoires lorsque la page est chargée
    widget.remoteRepertoire.ecouterEvenements(widget.remoteRepertoire,
        widget.zipRepertoire, widget.localRepertoire);   
  }

  @override
  void dispose() {
    // Assurez-vous de fermer le StreamController et d'annuler la souscription
    _eventStreamController?.close();
    super.dispose();
  }

  String afficherPermissions(List<RepertoirePermissions> permissions) {
    if (permissions.isEmpty) {
      return 'Aucune permission définie';
    }
    return permissions.map((perm) => perm.value).toSet().join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Détails des Répertoires'),
        backgroundColor: Colors.white,
      ),
      body: Row(
        children: <Widget>[
          // Colonne gauche avec les détails des répertoires
          Expanded(
            flex: 2, // Occupe 1/3 de l'espace
            child: Align(
              child: SingleChildScrollView(
                // Ajout du scroll ici
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildRepertoireItem(
                          'REMOTE', widget.remoteRepertoire, Icons.folder),
                      const SizedBox(height: 30),
                      _buildRepertoireItem(
                          'ZIP', widget.zipRepertoire, Icons.folder),
                      const SizedBox(height: 30),
                      _buildRepertoireItem(
                          'LOCALE', widget.localRepertoire, Icons.folder),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Colonne droite avec le cadre géant pour visualisation
          Expanded(
            flex: 5, // Occupe 2/3 de l'espace
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: selectedRepertoire == null
                    ? Center(
                        child: Text(
                          'Sélectionnez un répertoire pour voir les détails',
                          style: TextStyle(
                              fontSize: 18, fontStyle: FontStyle.italic),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildRepertoireDetails(selectedRepertoire!),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour chaque bloc de répertoire
  Widget _buildRepertoireItem(
      String title, Repertoire repertoire, IconData icon) {
    final isHovered = _scaleMap[title] ?? false;
    final isSelected = selectedRepertoire == repertoire;
    return MouseRegion(
        onEnter: (_) {
          setState(() {
            _scaleMap[title] = true;
          });
        },
        onExit: (_) {
          setState(() {
            _scaleMap[title] = false;
          });
        },
        child: AnimatedScale(
            scale: isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedRepertoire = repertoire;
                  _scaleMap[title] = true;
                });
              },
              child: Card(
                color: Colors.white,
                elevation: isSelected ? 7 : (isHovered ? 8 : 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: [
                                Icon(icon, size: 24, color: Colors.black),
                                const SizedBox(width: 15),
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('Nom: ${repertoire.name}',
                                style: const TextStyle(
                                  fontSize: 14,
                                )),
                            const SizedBox(height: 6),
                            Text(
                              'Chemin: ${repertoire.path}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Taille',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Type: ${repertoire.type}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Status:',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        10), // Espacement entre le texte "Status" et la pastille
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: repertoire.status ==
                                            RepertoireStatus.surveille
                                        ? const Color.fromARGB(255, 27, 225,
                                            34) // Couleur de la pastille pour "Surveillé"
                                        : const Color.fromARGB(255, 201, 50,
                                            39), // Couleur de fond de la pastille
                                    borderRadius: BorderRadius.circular(
                                        12), // Forme arrondie
                                  ),
                                  child: Text(
                                    repertoire.status ==
                                            RepertoireStatus.surveille
                                        ? 'Surveillé'
                                        : 'Non surveillé',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'Permissions: ${afficherPermissions(repertoire.permissions)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
  }

  // Détails du répertoire sélectionné dans le cadre géant
  Widget _buildRepertoireDetails(Repertoire repertoire) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Détails du répertoire sélectionné',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Nom: ${repertoire.name}'),
        Text('Chemin: ${repertoire.path}'),
        Text(
            'Taille: Nombre de dossiers: -- Nombre de fichiers:  -- Taille: octets'),
        Text('Type: ${repertoire.type}'),
        Text(
            'Status: ${repertoire.status == RepertoireStatus.surveille ? "Surveillé" : "Non surveillé"}'),
        Text('Permissions: ${afficherPermissions(repertoire.permissions)}'),
        const SizedBox(height: 20),
        Text(
          'Ici, vous pouvez visualiser et écouter les modifications en temps réel.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        // Vous pouvez ajouter ici des widgets pour visualiser ou écouter des modifications dans le répertoire.
      ],
    );
  }
}
