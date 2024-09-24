import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../services/token_service.dart';
import '../sockets/messages_socket_manager.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  ChatScreen({required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Future<Map<String, dynamic>> _chatDetailsFuture;
  String? _myEmail;
  final MessagesSocketManager messagesSocketManager = MessagesSocketManager();

  @override
  void initState() {
    super.initState();
    _chatDetailsFuture = ChatService().getChatDetails(widget.chatId);
    _fetchMyEmail();
    messagesSocketManager.connect(widget.chatId);
    messagesSocketManager.messageSocket.on('actuMessages', (data) {
      _refreshMessages();
    });
  }

  @override
  void dispose() {
    messagesSocketManager.disconnect();
    super.dispose();
  }

  void _refreshMessages() async {
    var chatDetails = await ChatService().getChatDetails(widget.chatId);
    setState(() {
      _chatDetailsFuture = Future.value(chatDetails);
    });
  }

  Future<void> _fetchMyEmail() async {
    _myEmail = await getEmail();
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageContent = _messageController.text;
    const messageType = 'text';

    try {
      await ChatService()
          .sendMessage(widget.chatId, messageType, messageContent);
      _messageController.clear();
      messagesSocketManager.messageSocket.emit('actuMessages', {
        'chatId': widget.chatId,
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _chatDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Chargement...');
            } else if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            final participants = snapshot.data!['participants'] as List;
            final filteredParticipants = participants
                .where((participant) => participant['email'] != _myEmail)
                .map((participant) =>
                    '${participant['firstName']} ${participant['lastName']}')
                .toList();

            return Text(
              filteredParticipants.join(', '),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            );
          },
        ),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _chatDetailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final isGroup = snapshot.data!['group'];

              return isGroup == true
                  ? IconButton(
                      icon: const Icon(Icons.group),
                      onPressed: () {
                        Navigator.pushNamed(
                            context, '/chat-participants/${widget.chatId}');
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _chatDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final messages = snapshot.data!['messages'] as List<Message>;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final formattedDate = DateFormat('dd/MM/yy HH:mm')
                        .format(message.date.toLocal());

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: message.senderEmail == _myEmail
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (message.senderEmail != _myEmail) ...[
                            CircleAvatar(
                              backgroundImage: message.senderPicture == '/'
                                  ? const AssetImage(
                                      'assets/images/defaultProfilPicture.png')
                                  : NetworkImage(
                                      'http://localhost:5000${message.senderPicture}'),
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  message.senderEmail == _myEmail
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                if (message.senderEmail != _myEmail)
                                  Text(message.senderName),
                                Text(formattedDate,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 130,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: message.senderEmail == _myEmail
                                        ? Colors.greenAccent[400]
                                        : Colors.blue[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(message.content),
                                ),
                              ],
                            ),
                          ),
                          if (message.senderEmail == _myEmail) ...[
                            const SizedBox(width: 10),
                            CircleAvatar(
                              backgroundImage: message.senderPicture == '/'
                                  ? const AssetImage(
                                      'assets/images/defaultProfilPicture.png')
                                  : NetworkImage(
                                      'http://localhost:5000${message.senderPicture}'),
                              radius: 20,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                        hintText: 'Écrivez un message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
