

import 'dart:io';

bool isTemporaryFile(String path) {
  final tempExtensions = ['.tmp', '.part']; // Extensions à ignorer
  return tempExtensions.any((ext) => path.endsWith(ext));
}