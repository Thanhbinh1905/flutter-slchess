import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/constants.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  String? _uploadedImageUrl;
  final String _idToken =
      "eyJraWQiOiJcL3I1OU5BYWtWakc0VWtwaFlFcHNlSHZ0bThkaDQyYlJPMFprcU5IV1Uxaz0iLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoiUWNPUjVtWXJRczNxcTM0ZGtXQTY3QSIsInN1YiI6ImE5OGUzNDE4LWIwOTEtNzA3My1kY2FhLWYwZDRmYWI0YWMxNyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX2Jua0hMazRJeSIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjIiLCJvcmlnaW5fanRpIjoiMmMyYzdhZmQtZjgwNC00MWUxLThjYjgtZjJmZTBlMGI0NjMzIiwiYXVkIjoiYTc0Mmtpa2ludWdydW1oMTgzbWhqYTduZiIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQzNzY2OTgwLCJleHAiOjE3NDM4NTMzODAsImlhdCI6MTc0Mzc2Njk4MCwianRpIjoiOTllN2E0NzAtMDEwZC00ZTE3LWI2Y2ItNmEyNWE3YzAyZjI4IiwiZW1haWwiOiJ0ZXN0dXNlcjJAZ21haWwuY29tIn0.xs0v7orUyWKHnvO9q7WlB2_wrmcH6FV5VEt9sijdODWLAFgdsADkdn11IZI9wnj_lsQm4-669o7A7Fc8fe5xpALuQGvFVl_bPf_7cGi0M0jEyt51zVnyRgB8EiFSm727_DRDskFQrnYxuicVbnr3vkzP1JFD6YRipjutwa_gG3B1xdVsgl280N0p9x1l26TdrhUAP_RRLjZSWmyk0bSWRS_V7utwPnTmOrzQjp25wSwgL6TLkYyCEEfrsqqXT9v3oWiSfu6D-fnnAX0jUcKW367DwTbHTRWhrvS02HpJFR_RfnTos_JCln0NFr6Lrac9NpV0u9MVkKKm_PfM7Fd4MQ"; // Thay token thật ở đây
  static final String _presignedUrlApi =
      ApiConstants.getUploadImageUrl; // API lấy Presigned URL

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

  /// Lấy Presigned URL từ server
  Future<String?> _getPresignedUrl() async {
    try {
      final response = await http.post(
        Uri.parse(_presignedUrlApi),
        headers: {'Authorization': _idToken},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['url'];
      } else {
        print('❌ Lỗi lấy Presigned URL: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Lỗi khi lấy URL: $error');
    }
    return null;
  }

  /// Upload ảnh lên S3
  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước!')),
      );
      return;
    }

    String? presignedUrl = await _getPresignedUrl();
    if (presignedUrl == null) return;

    try {
      final bytes = await _image!.readAsBytes();
      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': 'image/png'}, // hoặc 'image/jpeg'
        body: bytes,
      );

      if (response.statusCode == 200) {
        setState(() {
          _uploadedImageUrl = presignedUrl.split('?')[0]; // Lấy URL hiển thị
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Upload thành công!')),
        );
      } else {
        print('❌ Upload thất bại: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Lỗi khi upload: $error');
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

            const SizedBox(height: 20),

            // Hiển thị ảnh đã upload lên server
            _uploadedImageUrl != null
                ? Column(
                    children: [
                      const Text("Ảnh đã upload:"),
                      Image.network(_uploadedImageUrl!, height: 150),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
