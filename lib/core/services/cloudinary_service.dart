import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as path;
import 'package:wisecare_staff/core/config/env.dart';

class CloudinaryService {
  late final CloudinaryPublic cloudinary;
  bool _isInitialized = false;

  CloudinaryService() {
    try {
      final cloudName = Env.cloudinaryCloudName;
      final uploadPreset = Env.cloudinaryUploadPreset;

      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        print('Warning: Cloudinary credentials not properly configured');
        _isInitialized = false;
      } else {
        cloudinary = CloudinaryPublic(
          cloudName,
          uploadPreset,
          cache: false,
        );
        _isInitialized = true;
      }
    } catch (e) {
      print('Error initializing Cloudinary: $e');
      _isInitialized = false;
    }
  }

  Future<CloudinaryResponse> uploadFile(File file, String folder) async {
    if (!_isInitialized) {
      throw Exception('Cloudinary not properly initialized');
    }

    try {
      final fileName = path.basename(file.path);
      final fileType = getFileType(fileName);

      if (!isValidFileType(fileName)) {
        throw Exception(
            'Invalid file type. Supported types are: PDF, DOC, DOCX, JPG, JPEG, PNG');
      }

      final cloudinaryFile = CloudinaryFile.fromFile(
        file.path,
        folder: folder,
        resourceType: CloudinaryResourceType.Auto,
      );

      final response = await cloudinary.uploadFile(cloudinaryFile);
      return response;
    } catch (e) {
      print('Cloudinary upload error: $e');
      rethrow;
    }
  }

  Future<CloudinaryResponse> uploadImageBytes(
      List<int> imageBytes, String folder, String filename) async {
    if (!_isInitialized) {
      throw Exception('Cloudinary not properly initialized');
    }

    try {
      if (!isValidFileType(filename)) {
        throw Exception(
            'Invalid file type. Supported types are: JPG, JPEG, PNG');
      }

      final cloudinaryFile = CloudinaryFile.fromBytesData(
        imageBytes,
        folder: folder,
        identifier: filename,
        resourceType: CloudinaryResourceType.Image,
      );

      final response = await cloudinary.uploadFile(cloudinaryFile);
      return response;
    } catch (e) {
      print('Cloudinary upload error: $e');
      rethrow;
    }
  }

  String getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    if (['.pdf'].contains(extension)) {
      return 'pdf';
    } else if (['.doc', '.docx'].contains(extension)) {
      return 'document';
    } else if (['.jpg', '.jpeg', '.png'].contains(extension)) {
      return 'image';
    }

    return 'unknown';
  }

  bool isValidFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    return ['.pdf', '.doc', '.docx', '.jpg', '.jpeg', '.png']
        .contains(extension);
  }
}
