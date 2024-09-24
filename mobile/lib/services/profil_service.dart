import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import './token_service.dart';

class ProfilService {
  final String baseUrl = 'http://localhost:5000';

  Future<Map<String, dynamic>> getUserData() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<bool> uploadProfilePicture(File imageFile) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final mimeTypeData =
          lookupMimeType(imageFile.path, headerBytes: [0xFF, 0xD8])?.split('/');
      if (mimeTypeData == null) {
        throw Exception('Type de fichier non supporté');
      }

      final uri = Uri.parse('$baseUrl/profile/edit-picture');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = token;

      request.files.add(await http.MultipartFile.fromPath(
        'picture',
        imageFile.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Erreur lors de la mise à jour de la photo');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  Future<bool> deleteProfile() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final uri = Uri.parse('$baseUrl/profile/delete');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Erreur lors de la suppression du profil');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
