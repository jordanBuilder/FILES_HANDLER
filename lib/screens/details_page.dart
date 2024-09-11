import 'package:flutter/material.dart';
import '../models/repertoire.dart';

class DetailsPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails des Répertoires'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildRepertoireDetails('Dossier REMOTE', remoteRepertoire),
            const SizedBox(height: 20),
            _buildRepertoireDetails('Dossier ZIP', zipRepertoire),
            const SizedBox(height: 20),
            _buildRepertoireDetails('Dossier LOCALE', localRepertoire),
          ],
        ),
      ),
    );
  }

  Widget _buildRepertoireDetails(String title, Repertoire repertoire) {
    return Card(
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
    );
  }
}
