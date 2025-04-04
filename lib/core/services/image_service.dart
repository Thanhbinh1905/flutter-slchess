import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static String getPresignedUrlApi = ApiConstants.getUploadImageUrl;

  /// Lấy Presigned URL từ backend
  Future<String> getPresignedUrl(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse(getPresignedUrlApi),
        headers: {'Authorization': idToken},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['url'];
      } else {
        throw Exception('Failed to get presigned URL: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error getting presigned URL: $error');
    }
  }

  /// Chọn ảnh từ thư viện
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Upload ảnh lên Presigned URL
  Future<bool> uploadImage(File imageFile, String uploadUrl) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'image/png'
        }, // hoặc 'image/jpeg' tùy loại ảnh
        body: bytes,
      );

      return response.statusCode == 200;
    } catch (error) {
      print('Upload error: $error');
      return false;
    }
  }

  /// Hàm chính để upload ảnh
  void uploadUserAvatar(String idToken) async {
    File? image = await pickImage();
    if (image == null) {
      print("Không có ảnh nào được chọn.");
      return;
    }

    String presignedUrl;
    try {
      presignedUrl = await getPresignedUrl(idToken);
    } catch (e) {
      print("Lỗi khi lấy Presigned URL: $e");
      return;
    }

    bool success = await uploadImage(image, presignedUrl);
    if (success) {
      print("✅ Upload thành công!");
      print("📸 Ảnh đã được lưu tại: ${presignedUrl.split('?')[0]}");
    } else {
      print("❌ Upload thất bại!");
    }
  }
}
