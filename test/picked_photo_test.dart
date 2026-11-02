import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stallseeker/core/services/storage_service.dart';

void main() {
  test('browser photo bytes preserve the image and infer PNG upload metadata',
      () async {
    final bytes =
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    final photo =
        await PickedPhoto.fromFile(XFile.fromData(bytes, name: 'photo.png'));
    expect(photo.bytes, orderedEquals(bytes));
    expect(photo.contentType, 'image/png');
  });

  test('JPEG photos preserve their content type without native file access',
      () async {
    final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]);
    final photo = await PickedPhoto.fromFile(
        XFile.fromData(bytes, mimeType: 'image/jpeg'));
    expect(photo.contentType, 'image/jpeg');
    expect(photo.bytes, orderedEquals(bytes));
  });
}
