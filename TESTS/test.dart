// ignore_for_file: unused_local_variable

import 'package:files_handler/models/fichier.dart';

void main() async {
  //   Fichier fichierTest = Fichier(
  //   name: 'test.txt',
  //   path: 'C:\\Users\\Lenovo\\Desktop\\test.txt', // Assurez-vous que ce fichier existe
  //   size: 1024,
  //   permissions: ['read', 'write'],
  // );

  // String result = fichierTest.zipper('C:\\Users\\Lenovo\\Desktop\\test.zip');
  // print(result);

  Fichier fichierTest = Fichier(
    path:
        'C:\\Users\\Lenovo\\Desktop\\test.zip', // Assurez-vous que ce fichier existe
  );

  // String result = fichierTest.dezipper('C:\\Users\\Lenovo\\Desktop\\test.zip','C:\\Users\\Lenovo\\Desktop\\extracted');

  // print(result);

  // String result = fichierTest.copier(fichierTest.path,'C:\\Users\\Lenovo\\Documents\\CopiedFiles');

  // print(result);
  // String result = fichierTest.deplacer(fichierTest.path,'C:\\Users\\Lenovo\\CuttedFiles');
}
