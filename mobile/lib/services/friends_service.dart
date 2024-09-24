import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/friend.dart';
import './token_service.dart';

class FriendsService {
  final String baseUrl = 'http://localhost:5000';

  Future<Map<String, List<Friend>>> getFriendsAndRequests() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Friend> friends = (data['friends'] as List)
            .map((friendData) => Friend(
                  firstName: friendData['firstName'],
                  lastName: friendData['lastName'],
                  email: friendData['email'],
                  picture: friendData['picture'],
                ))
            .toList();

        List<Friend> friendRequests = (data['friendRequests'] as List)
            .map((requestData) => Friend(
                  firstName: requestData['firstName'],
                  lastName: requestData['lastName'],
                  email: requestData['email'],
                  picture: requestData['picture'],
                ))
            .toList();

        return {
          'friends': friends,
          'friendRequests': friendRequests,
        };
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<Map<String, dynamic>> searchFriendByEmail(String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/search?email=$email'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Erreur lors de la recherche de l\'ami');
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<String> sendFriendRequest(String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/request'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<String> acceptFriendRequest(String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/accept'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<String> rejectFriendRequest(String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/reject'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<String> unfriend(String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/friends/unfriend'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }
}
