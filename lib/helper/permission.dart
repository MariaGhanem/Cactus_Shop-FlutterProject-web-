import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (await Permission.photos.isDenied || await Permission.storage.isDenied) {
    await [
      Permission.storage,
      Permission.photos,
    ].request();
  }
}