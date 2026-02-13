import 'dart:convert';
import 'dart:io';
import 'package:cute_live/data/local/secure_storage/secure_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../model/user_profile_model.dart';

class UserRepository {
  final String baseUrl = "https://gf-live-backend.onrender.com/api/v1";

  Future<User> getUserProfile() async {
    final token = await SecureStorage().getToken();

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/'),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
    );

    final jsonData = jsonDecode(response.body);

    debugPrint("Status code: ${response.statusCode}");
    debugPrint("Response body: ${response.body}");

    if (response.statusCode == 200 && jsonData['status'] == true) {
      final model = UserProfileResponse.fromJson(jsonData);
      return model.data.user;
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to load profile');
    }
  }

  Future<void> updateUserProfile({
    required String name,
    String? phone,
    String? gender,
    String? location,
    String? bio,
    String? country,
    File? imageFile,
  }) async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    var uri = Uri.parse('$baseUrl/user/');
    var request = http.MultipartRequest('PATCH', uri);
    request.headers['authorization'] = token;

    // Combine all fields into a single JSON string
    final Map<String, dynamic> data = {
      "name": name,
      "phone": phone ?? "",
      "gender": gender ?? "",
      "location": location ?? "",
      "bio": bio ?? "",
      "country": country ?? "",
    };

    request.fields['data'] = jsonEncode(data); // << Important: send as JSON string

    // Add image if exists
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint("Status code: ${response.statusCode}");
    debugPrint("Response body: ${response.body}");

    final jsonData = jsonDecode(response.body);
    if (response.statusCode != 200 || jsonData['status'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    final response = await http.patch(
      Uri.parse('$baseUrl/user/changePassword'),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    debugPrint("Old: $oldPassword");
    debugPrint("New: $newPassword");
    debugPrint("Token: $token");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.body}");

    final jsonData = jsonDecode(response.body);

    if (response.statusCode != 200 || jsonData['status'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to change password');
    }
  }




}
