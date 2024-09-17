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
  Stream<String>? _eventStream;
   @override
  void initState() {
    super.initState();
    
     _eventStreamController = StreamController<String>.broadcast();
    _eventStream = _eventStreamController!.stream;

    // Démarrer la surveillance des répertoires lorsque la page est chargée
    widget.remoteRepertoire.ecouterEvenements(
    widget.remoteRepertoire, 
    widget.zipRepertoire, 
    widget.localRepertoire
  );

  widget.localRepertoire.ecouterEvenements(
    widget.remoteRepertoire, 
    widget.zipRepertoire, 
    widget.localRepertoire
  );
  }
  @override
  void dispose() {
    // Assurez-vous de fermer le StreamController lorsque le widget est détruit
    _eventStreamController?.close();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails des Répertoires'),
      ),
      body: Row(
        children: <Widget>[
          // Colonne gauche avec les détails des répertoires
          Expanded(
            flex: 2, // Occupe 1/3 de l'espace
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildRepertoireItem('Dossier REMOTE', widget.remoteRepertoire),
                  const SizedBox(height: 20),
                  _buildRepertoireItem('Dossier ZIP', widget.zipRepertoire),
                  const SizedBox(height: 20),
                  _buildRepertoireItem('Dossier LOCALE', widget.localRepertoire),
                ],
              ),
            ),
          ),
          // Colonne droite avec le cadre géant pour visualisation
          Expanded(
            flex: 5, // Occupe 2/3 de l'espace
            child: Container(
              color: Colors.grey[200], // Couleur de fond pour distinguer la zone
              child: selectedRepertoire == null
                  ? Center(
                      child: Text(
                        'Sélectionnez un répertoire pour voir les détails',
                        style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildRepertoireDetails(selectedRepertoire!),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour chaque bloc de répertoire
  Widget _buildRepertoireItem(String title, Repertoire repertoire) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedRepertoire = repertoire;
        });
      },
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Nom: ${repertoire.name}'),
              Text('Chemin: ${repertoire.path}'),
              Text('Taille: ${repertoire.size} octets'),
              Text('Type: ${repertoire.type}'),
              Text('Status: ${repertoire.status == RepertoireStatus.surveille ? "Surveillé" : "Non surveillé"}'),
            ],
          ),
        ),
      ),
    );
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
        Text('Taille: ${repertoire.size} octets'),
        Text('Type: ${repertoire.type}'),
        Text('Status: ${repertoire.status == RepertoireStatus.surveille ? "Surveillé" : "Non surveillé"}'),
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
