
String extractFileNameFromPath(String path) {
  String fileNameWithoutExtension = basenameWithoutExtension(path);
  String zipFileName = '$fileNameWithoutExtension.zip';
  return zipFileName;
}
