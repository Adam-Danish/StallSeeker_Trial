import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the gallery picker. Returns null if the vendor backed out
  // without choosing anything.
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Uploads a stall's cover photo. Always uses the same file name per
  // vendor, so re-uploading overwrites the old photo instead of leaving
  // unused files in Storage.
  Future<String> uploadStallImage(String vendorId, File imageFile) async {
    final ref = _storage.ref().child('stall_images/$vendorId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Uploads a photo for one menu item. Named by itemId so each dish has
  // its own file, and re-uploading a photo for the same dish overwrites it.
  Future<String> uploadMenuItemImage(
    String vendorId,
    String itemId,
    File imageFile,
  ) async {
    final ref = _storage.ref().child('menu_images/$vendorId/$itemId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}
