import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/token_service.dart';

class ParticipantsScreen extends StatefulWidget {
  final String chatId;

  ParticipantsScreen({required this.chatId});

  @override
  _ParticipantsScreenState createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  String? _myEmail;
  List<dynamic> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchMyEmail();
    _loadParticipants();
  }

  Future<void> _fetchMyEmail() async {
    _myEmail = await getEmail();
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

  Future<void> _removeParticipant(String email) async {
    try {
      await ChatService().removeParticipant(widget.chatId, email);
      await _loadParticipants();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$email a été supprimé avec succès.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la suppression du participant: $e')),
      );
    }
  }

  Future<void> _leaveChat() async {
    try {
      await ChatService().leaveChat(widget.chatId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez quitté la conversation.')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la sortie de la conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
      ),
      body: _participants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _participants.length,
                    itemBuilder: (context, index) {
                      final participant = _participants[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: participant['picture'] == '/'
                              ? const AssetImage(
                                  'assets/images/defaultProfilPicture.png')
                              : NetworkImage(
                                      'http://localhost:5000${participant['picture']}')
                                  as ImageProvider,
                        ),
                        title: Text(
                            '${participant['firstName']} ${participant['lastName']}'),
                        subtitle: Text(participant['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index == 0)
                              Image.asset(
                                'assets/images/crown.png',
                                width: 24,
                                height: 24,
                              ),
                            if (_participants.isNotEmpty &&
                                _participants[0]['email'] == _myEmail &&
                                index != 0)
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _removeParticipant(participant['email']);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_participants.isNotEmpty &&
                    _participants[0]['email'] == _myEmail)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.75,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, '/add-participants/${widget.chatId}');
                        },
                        child: const Text('Ajouter des participants'),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: ElevatedButton(
                      onPressed: _leaveChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text(
                        'Quitter la conversation',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
