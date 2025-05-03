import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from camera or gallery
  static Future<File?> pickImage({required bool fromCamera}) async {
    final XFile? image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxHeight: 600,
      maxWidth: 600,
      imageQuality: 85,
    );

    if (image == null) return null;
    return File(image.path);
  }
}
