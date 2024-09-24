import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import './token_service.dart';

class AuthService {
  final String baseUrl = 'http://localhost:5000';

  Future<User?> signup(
      String firstName, String lastName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password
      }),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return User(
          firstName: firstName,
          lastName: lastName,
          email: email,
          token: data['token'],
          picture: '');
    } else {
      throw Exception('Failed to sign up');
    }
  }

  Future<User?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setToken(data['token'], email);
      return User(
          firstName: data['firstName'],
          lastName: data['lastName'],
          email: email,
          token: data['token'],
          picture: data['picture']);
    } else {
      throw Exception('Failed to log in');
    }
  }
}
