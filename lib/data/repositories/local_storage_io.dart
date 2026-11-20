import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> readLocalJson(String filename) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    if (await file.exists()) {
      return await file.readAsString();
    }
  } catch (_) {}
  return null;
}

Future<void> writeLocalJson(String filename, String content) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
  } catch (_) {}
}
