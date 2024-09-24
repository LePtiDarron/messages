import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import './token_service.dart';

class ChatService {
  final String baseUrl = 'http://localhost:5000';

  Future<String> getChatId(List<String> participants) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat?participants=${participants.join(',')}'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chatId'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<String> newGroupChat(List<String> participants) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/chat/new-group?participants=${participants.join(',')}'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['chatId'];
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<Map<String, dynamic>> getChatDetails(String chatId) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$chatId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final participants = (data['participants'] as List)
            .map((participant) => {
                  'firstName': participant['firstName'],
                  'lastName': participant['lastName'],
                  'email': participant['email'],
                  'picture': participant['picture'],
                })
            .toList();

        final messages = (data['messages'] as List)
            .map((msg) => Message(
                  content: msg['content'],
                  date: DateTime.parse(msg['date']),
                  type: msg['type'],
                  senderName: msg['senderName'],
                  senderEmail: msg['senderEmail'],
                  senderPicture: msg['senderPicture'],
                ))
            .toList();

        final readBy =
            (data['readBy'] as List).map((userId) => userId as String).toList();

        return {
          'participants': participants,
          'messages': messages,
          'readBy': readBy,
          'group': data['group'],
        };
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<void> sendMessage(String chatId, String type, String content) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/$chatId/message'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': type,
          'content': content,
        }),
      );

      if (response.statusCode != 201) {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllChats() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/all'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        return data.map((chat) {
          final participants = (chat['participants'] as List)
              .map((participant) => {
                    'firstName': participant['firstName'],
                    'lastName': participant['lastName'],
                    'email': participant['email'],
                    'picture': participant['picture'],
                  })
              .toList();

          final lastMessage = chat['lastMessage'] != null
              ? {
                  'content': chat['lastMessage']['content'],
                  'date': DateTime.parse(chat['lastMessage']['date']),
                  'senderName': chat['lastMessage']['senderName'],
                  'senderEmail': chat['lastMessage']['senderEmail'],
                }
              : null;

          return {
            'chatId': chat['chatId'],
            'participants': participants,
            'lastMessage': lastMessage,
          };
        }).toList();
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<void> removeParticipant(String chatId, String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/$chatId/participant'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<void> leaveChat(String chatId) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/$chatId/leave'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }

  Future<void> addParticipant(String chatId, String email) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/$chatId/participant'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Erreur serveur: $e');
    }
  }
}
