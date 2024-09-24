import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/token_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Future<List<Map<String, dynamic>>>? _chatsFuture;
  String? _myEmail;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMyEmail();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshChats();
    });
  }

  Future<void> _fetchMyEmail() async {
    _myEmail = await getEmail();
    _refreshChats();
  }

  void _refreshChats() {
    setState(() {
      _chatsFuture = ChatService().getAllChats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildParticipantsAvatars(List<Map<String, dynamic>> participants) {
    final displayParticipants = participants.take(3).toList();

    return SizedBox(
      width: 60,
      child: Stack(
        children: List.generate(displayParticipants.length, (index) {
          final participant = displayParticipants[index];
          final imageProvider = participant['picture'] != null && participant['picture'] != '/'
              ? NetworkImage('http://localhost:5000${participant['picture']}')
              : const AssetImage('assets/images/defaultProfilPicture.png')
                  as ImageProvider;

          return Positioned(
            left: index * 15.0,
            child: CircleAvatar(
              radius: 20,
              backgroundImage: imageProvider,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _chatsFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _chatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final chats = snapshot.data;

                if (chats == null || chats.isEmpty) {
                  return const Center(
                      child: Text('Aucune conversation trouvée.'));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    final filteredParticipants = chat['participants']
                        .where((p) => p['email'] != _myEmail)
                        .toList();

                    final participantsNames = filteredParticipants
                        .map((p) => '${p['firstName']} ${p['lastName']}')
                        .join(', ');

                    final lastMessage = chat['lastMessage'] != null
                        ? chat['lastMessage']['content']
                        : 'Pas de messages encore';

                    return ListTile(
                      title: Text(participantsNames),
                      subtitle: Text(lastMessage),
                      leading: _buildParticipantsAvatars(filteredParticipants),
                      onTap: () {
                        Navigator.pushNamed(context, '/chat/${chat['chatId']}');
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/new-chat');
        },
        tooltip: 'Nouvelle conversation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
