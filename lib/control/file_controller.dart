import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'db_provider.dart';

class FileController {
  Future saveImageGallery(File image) async {
    Uint8List _buffer = await image.readAsBytes();
    await ImageGallerySaver.saveImage(_buffer);
  }

  Future<String> saveLocalImage(File image) async {
    final path = await DBProvider.documentsDirectory.path;
    String imageName = Uuid().v4();
    String imagePath = '$path/$imageName.png';
    File imageFile = File(imagePath);
    await imageFile.writeAsBytes(await image.readAsBytes());
    return '$imageName.png';
  }
}
