import 'dart:convert';
import 'dart:io';
import 'package:cute_live/data/local/secure_storage/secure_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../model/user_profile_model.dart';

class UserRepository {
  final String baseUrl = "https://gs-live-backend.vercel.app/api/v1";

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

    debugPrint("Status code: ${response.request!.url}");
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
    String? displayName,
    String? phone,
    String? gender,
    String? location,
    String? bio,
    String? country,
    int? photoIndex,
    File? imageFile,
    List<String>? myTags,
  }) async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    var uri = Uri.parse('$baseUrl/user/');
    var request = http.MultipartRequest('PATCH', uri);
    request.headers['authorization'] = token;

    final Map<String, dynamic> data = {
      if (displayName != null) "displayName": displayName,
      if (phone != null) "phone": phone,
      if (gender != null) "gender": gender,
      if (location != null) "location": location,
      if (bio != null) "bio": bio,
      if (country != null) "country": country,
      if (photoIndex != null) "photoIndex": photoIndex,
      if (myTags != null) "myTags": myTags,
    };

    request.fields['data'] = jsonEncode(data);

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
  } // FIX 1: Added missing closing brace for changePassword — getAllTags and saveMyTags
  // were trapped inside this method body, making them invisible to UserRepository.

  Future<List<Tag>> getAllTags() async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    final response = await http.get(
      Uri.parse('$baseUrl/tags/'),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
    );

    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData['status'] == true) {
      final List<dynamic> data = jsonData['data'];
      return data.map((i) => Tag.fromJson(i)).toList();
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to load tags');
    }
  }

  Future<List<Tag>> getMyTags() async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    final response = await http.get(
      Uri.parse('$baseUrl/tags/my-tags/all'),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
    );

    final jsonData = jsonDecode(response.body);

    debugPrint("getMyTags status: ${response.statusCode}");
    debugPrint("getMyTags body: ${response.body}");

    if (response.statusCode == 200 && jsonData['status'] == true) {
      final List<dynamic> data = jsonData['data'];
      // Each item has a nested 'tag' object: { id, hostId, tagId, tag: { id, name, category } }
      return data
          .where((item) => item['tag'] != null)
          .map((item) => Tag.fromJson(item['tag']))
          .toList();
    } else {
      throw Exception(jsonData['message'] ?? 'Failed to load my tags');
    }
  }

  Future<void> deleteMyTag(String tagId) async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    final request = http.Request(
      'DELETE',
      Uri.parse('$baseUrl/tags/my-tags/$tagId'),
    );
    request.headers['authorization'] = token;

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final jsonData = jsonDecode(response.body);

    debugPrint("deleteMyTag($tagId) status: ${response.statusCode}");
    debugPrint("deleteMyTag body: ${response.body}");

    if (response.statusCode != 200 || jsonData['status'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to remove tag');
    }
  }

  Future<void> saveMyTags(List<String> tagIds) async {
    final token = await SecureStorage().getToken();
    if (token == null) throw Exception('Token not found');

    final response = await http.post(
      Uri.parse('$baseUrl/tags/my-tags'),
      headers: {
        'authorization': token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"tagIds": tagIds}),
    );

    final jsonData = jsonDecode(response.body);

    if (response.statusCode != 200 || jsonData['status'] != true) {
      throw Exception(jsonData['message'] ?? 'Failed to save tags');
    }
  }
}