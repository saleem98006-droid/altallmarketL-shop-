import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {

  // ضغط ملف مباشرة وإرجاع Base64
  static Future<String?> compressFile(File? file) async {
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return await compressToBase64(bytes);
  }

  // 🔍 فحص إذا كانت الصورة PNG (غالبًا شفافة)
  static bool isTransparentImage(Uint8List bytes) {
    if (bytes.length > 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true; // PNG
    }
    return false; // JPEG أو غيره
  }

  // 🔥 ضغط الصورة وإرجاع Base64
  static Future<String> compressToBase64(Uint8List originalBytes) async {
    final isPng = isTransparentImage(originalBytes);

    final format = isPng ? CompressFormat.png : CompressFormat.jpeg;

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: isPng ? 90 : 80,
      minWidth: 1200,
      minHeight: 1200,
      format: format,
    );

    return base64Encode(compressedBytes);
  }
}