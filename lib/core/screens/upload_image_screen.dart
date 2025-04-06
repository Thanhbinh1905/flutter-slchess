import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_slchess/core/services/cognito_auth_service.dart';
import 'package:flutter_slchess/core/services/image_service.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  String? _uploadedImageUrl;
  final ImageService _imageService = ImageService();
  final CognitoAuth _cognitoAuth = CognitoAuth();

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Upload ảnh lên server
  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước')),
      );
      return;
    }

    try {
      final String? idToken = await _cognitoAuth.getStoredIdToken();
      if (idToken == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      // Lấy presigned URL
      final String presignedUrl = await _imageService.getPresignedUrl(idToken);

      // Upload ảnh
      final bool success =
          await _imageService.uploadImage(_image!, presignedUrl);

      if (success) {
        setState(() {
          _uploadedImageUrl = presignedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload ảnh thành công')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Upload ảnh thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Avatar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hiển thị ảnh đã chọn
            _image != null
                ? Image.file(_image!, height: 150)
                : const Icon(Icons.image, size: 100, color: Colors.grey),

            const SizedBox(height: 20),

            // Nút chọn ảnh
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text("Chọn ảnh"),
            ),

            const SizedBox(height: 10),

            // Nút upload ảnh
            ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: const Icon(Icons.upload),
              label: const Text("Upload Ảnh"),
            ),
          ],
        ),
      ),
    );
  }
}
