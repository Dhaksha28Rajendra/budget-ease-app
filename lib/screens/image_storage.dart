import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> savePickedImagePermanently(String pickedPath) async {
  final dir = await getApplicationDocumentsDirectory();
  final ext = p.extension(pickedPath);
  final fileName = "profile_${DateTime.now().millisecondsSinceEpoch}$ext";
  final newPath = p.join(dir.path, fileName);

  await File(pickedPath).copy(newPath);
  return newPath;
}
