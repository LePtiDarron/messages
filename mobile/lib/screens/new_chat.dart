import 'package:flutter/material.dart';
import '../services/friends_service.dart';
import '../services/chat_service.dart';
import '../models/friend.dart';
import '../services/token_service.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  _NewChatScreenState createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  Future<Map<String, List<Friend>>> _friendsFuture = Future.value({});
  List<Friend> _selectedFriends = [];
  String? _myEmail;

  @override
  void initState() {
    super.initState();
    _loadEmailAndFriends();
  }

  Future<void> _loadEmailAndFriends() async {
    _myEmail = await getEmail();
    setState(() {
      _friendsFuture = FriendsService().getFriendsAndRequests();
    });
  }

  void _toggleSelection(Friend friend) {
    setState(() {
      if (_selectedFriends.contains(friend)) {
        _selectedFriends.remove(friend);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  Future<void> _createConversation() async {
    if (_selectedFriends.isNotEmpty && _myEmail != null) {
      final emails = [_myEmail!] + _selectedFriends.map((f) => f.email).toList();
      try {
        final chatId = await ChatService().newGroupChat(emails);
        Navigator.of(context).pop();
        Navigator.pushNamed(context, '/chat/$chatId');
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un ami.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createConversation,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Friend>>>(
        future: _friendsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['friends']!.isEmpty) {
            return const Center(child: Text('Aucun ami trouvé.'));
          }

          final friends = snapshot.data!['friends']!;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final isSelected = _selectedFriends.contains(friend);

              return ListTile(
                title: Text('${friend.firstName} ${friend.lastName}'),
                leading: CircleAvatar(
                  backgroundImage: friend.picture == '/'
                      ? const AssetImage(
                          'assets/images/defaultProfilPicture.png')
                      : NetworkImage('http://localhost:5000${friend.picture}'),
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.green : null,
                ),
                onTap: () => _toggleSelection(friend),
              );
            },
          );
        },
      ),
    );
  }
}
