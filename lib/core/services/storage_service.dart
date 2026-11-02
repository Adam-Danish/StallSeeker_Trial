import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Image bytes work with both browser uploads and native photo pickers.
class PickedPhoto {
  const PickedPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;

  static Future<PickedPhoto> fromFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final type = bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50
        ? 'image/png'
        : bytes.length >= 12 && bytes[8] == 0x57 && bytes[9] == 0x45
            ? 'image/webp'
            : bytes.length >= 3 && bytes[0] == 0x47 && bytes[1] == 0x49
                ? 'image/gif'
                : file.mimeType ?? 'image/jpeg';
    return PickedPhoto(bytes, type);
  }
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the gallery picker. Returns null if the vendor backed out
  // without choosing anything.
  Future<PickedPhoto?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) {
      return null;
    }
    return PickedPhoto.fromFile(picked);
  }

  // Uploads a stall's cover photo. Always uses the same file name per
  // vendor, so re-uploading overwrites the old photo instead of leaving
  // unused files in Storage.
  Future<String> uploadStallImage(
      String vendorId, PickedPhoto imageFile) async {
    final ref = _storage.ref().child('stall_images/$vendorId.jpg');
    final upload = await ref.putData(
        imageFile.bytes, SettableMetadata(contentType: imageFile.contentType));
    final url = Uri.parse(await ref.getDownloadURL());
    // Reusing the storage object must still refresh Image.network caches.
    return url.replace(queryParameters: {
      ...url.queryParameters,
      'v': upload.metadata?.generation ??
          DateTime.now().microsecondsSinceEpoch.toString(),
    }).toString();
  }

  // Uploads a photo for one menu item. Named by itemId so each dish has
  // its own file, and re-uploading a photo for the same dish overwrites it.
  Future<String> uploadMenuItemImage(
    String vendorId,
    String itemId,
    PickedPhoto imageFile,
  ) async {
    final ref = _storage.ref().child('menu_images/$vendorId/$itemId.jpg');
    await ref.putData(
        imageFile.bytes, SettableMetadata(contentType: imageFile.contentType));
    return await ref.getDownloadURL();
  }

  Future<List<PickedPhoto>> pickReviewImages(int remaining) async {
    final picked =
        await _picker.pickMultiImage(maxWidth: 1080, imageQuality: 75);
    return Future.wait(
        picked.take(remaining.clamp(0, 5)).map(PickedPhoto.fromFile));
  }

  Future<String> uploadReviewImage(String vendorId, String customerId,
      String imageId, PickedPhoto imageFile) async {
    final ref = _storage
        .ref()
        .child('review_images/$vendorId/$customerId/$imageId.jpg');
    await ref.putData(
        imageFile.bytes, SettableMetadata(contentType: imageFile.contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteReviewImageUrl(
      String vendorId, String customerId, String url) async {
    final ref = _storage.refFromURL(url);
    if (!ref.fullPath.startsWith('review_images/$vendorId/$customerId/')) {
      throw ArgumentError('Review photo does not belong to this customer.');
    }
    await ref.delete();
  }
}
