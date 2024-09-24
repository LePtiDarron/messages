import 'package:flutter/material.dart';
import '../services/friends_service.dart';
import '../services/chat_service.dart';
import '../models/friend.dart';

class AddParticipantsScreen extends StatefulWidget {
  final String chatId;

  AddParticipantsScreen({required this.chatId});

  @override
  _AddParticipantsScreenState createState() => _AddParticipantsScreenState();
}

class _AddParticipantsScreenState extends State<AddParticipantsScreen> {
  Future<Map<String, List<Friend>>> _friendsFuture = Future.value({});
  List<dynamic> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadEmailAndFriends();
    _loadParticipants();
  }

  Future<void> _loadEmailAndFriends() async {
    setState(() {
      _friendsFuture = FriendsService().getFriendsAndRequests();
    });
  }

  Future<void> _loadParticipants() async {
    try {
      final chatDetails = await ChatService().getChatDetails(widget.chatId);
      setState(() {
        _participants = chatDetails['participants'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors du chargement des participants: $e')),
      );
    }
  }

  Future<void> _addParticipant(String email) async {
    try {
      await ChatService().addParticipant(widget.chatId, email);
      await _loadParticipants();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$email a été ajouté avec succès.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la suppression du participant: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des participants'),
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

              // Vérifier si l'ami est déjà dans la liste des participants
              final isAlreadyParticipant = _participants.any((participant) => participant['email'] == friend.email);

              return ListTile(
                title: Text('${friend.firstName} ${friend.lastName}'),
                leading: CircleAvatar(
                  backgroundImage: friend.picture == '/'
                      ? const AssetImage(
                          'assets/images/defaultProfilPicture.png')
                      : NetworkImage('http://localhost:5000${friend.picture}'),
                ),
                trailing: ElevatedButton(
                  onPressed: isAlreadyParticipant ? null : () => _addParticipant(friend.email),
                  child: const Text('Ajouter'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
