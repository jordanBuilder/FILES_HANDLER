import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class BackgroundService extends StatefulWidget {
  const BackgroundService({Key? key}) : super(key: key);

  @override
  _BackgroundServiceState createState() => _BackgroundServiceState();
}

class _BackgroundServiceState extends State<BackgroundService> {
  bool _isVisible = true;

  // Fonction pour vider les SharedPreferences et relancer le HomeScreen
  Future<void> _resetPaths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Vider les chemins stockés
    // Naviguer vers l'écran d'accueil pour redéfinir les chemins
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink(); // Masquer la fenêtre
    }

    return Positioned(
      bottom: 20, 
      right: 20,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          width: 200,
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(_isVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isVisible = !_isVisible; // Masquer la fenêtre
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _resetPaths,
                child: const Text('Redéfinir les chemins'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
