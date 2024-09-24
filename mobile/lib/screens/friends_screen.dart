import 'package:flutter/material.dart';
import 'package:mobile/services/friends_service.dart';
import 'package:mobile/services/chat_service.dart';
import 'package:mobile/models/friend.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../sockets/friends_socket_manager.dart';

class FriendsScreen extends StatefulWidget {
  final String email;

  const FriendsScreen({super.key, required this.email});

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, List<Friend>>> _friendsFuture;
  final TextEditingController _emailController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  bool _isRequestSent = false;
  late IO.Socket socket;
  final FriendsSocketManager friendsSocketManager = FriendsSocketManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _friendsFuture = FriendsService().getFriendsAndRequests();

    _tabController.addListener(() {
      if (_tabController.index != 2) {
        _resetSearch();
      }
    });

    friendsSocketManager.connect(widget.email);
    friendsSocketManager.friendSocket.on('actuFriends', (data) {
      _refreshFriendsAndRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    friendsSocketManager.disconnect();
    super.dispose();
  }

  void _refreshFriendsAndRequests() async {
    var friendsAndRequests = await FriendsService().getFriendsAndRequests();
    setState(() {
      _friendsFuture = Future.value(friendsAndRequests);
    });
  }

  void _resetSearch() {
    setState(() {
      _searchResult = null;
      _emailController.clear();
      _isRequestSent = false;
    });
  }

  Future<void> _acceptRequest(String email) async {
    try {
      final message =
          await FriendsService().acceptFriendRequest(email);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _friendsFuture = FriendsService().getFriendsAndRequests();
      });
      friendsSocketManager.friendSocket.emit('actuFriends', {
        'emails': [widget.email, email],
      });
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $error')));
    }
  }

  Future<void> _rejectRequest(String email) async {
    try {
      final message =
          await FriendsService().rejectFriendRequest(email);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _friendsFuture = FriendsService().getFriendsAndRequests();
      });
      friendsSocketManager.friendSocket.emit('actuFriends', {
        'emails': [widget.email, email],
      });
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $error')));
    }
  }

  Future<void> _unfriend(String email) async {
    try {
      final message = await FriendsService().unfriend(email);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _friendsFuture = FriendsService().getFriendsAndRequests();
      });
      friendsSocketManager.friendSocket.emit('actuFriends', {
        'emails': [widget.email, email],
      });
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Amis'),
          Tab(text: 'Demandes'),
          Tab(text: 'Ajouter'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<Map<String, List<Friend>>>(
            future: _friendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData ||
                  snapshot.data!['friends']!.isEmpty) {
                return const Center(child: Text('Aucun ami trouvé.'));
              }

              final friends = snapshot.data!['friends']!;

              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return ListTile(
                    title: Text('${friend.firstName} ${friend.lastName}'),
                    leading: CircleAvatar(
                      backgroundImage: friend.picture == '/'
                          ? const AssetImage(
                              'assets/images/defaultProfilPicture.png')
                          : NetworkImage(
                              'http://localhost:5000${friend.picture}'),
                    ),
                    onTap: () async {
                      try {
                        String chatId = await ChatService().getChatId(
                            [widget.email, friend.email]);
                        Navigator.pushNamed(context, '/chat/$chatId');
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $error')));
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _unfriend(friend.email),
                    ),
                  );
                },
              );
            },
          ),
          FutureBuilder<Map<String, List<Friend>>>(
            future: _friendsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              } else if (!snapshot.hasData ||
                  snapshot.data!['friendRequests']!.isEmpty) {
                return const Center(
                    child: Text('Aucune demande d\'ami trouvée.'));
              }

              final friendRequests = snapshot.data!['friendRequests']!;

              return ListView.builder(
                itemCount: friendRequests.length,
                itemBuilder: (context, index) {
                  final request = friendRequests[index];
                  return ListTile(
                    title: Text('${request.firstName} ${request.lastName}'),
                    subtitle: Text(request.email),
                    leading: CircleAvatar(
                      backgroundImage: request.picture == '/'
                          ? const AssetImage(
                              'assets/images/defaultProfilPicture.png')
                          : NetworkImage(
                              'http://localhost:5000${request.picture}'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _acceptRequest(request.email),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _rejectRequest(request.email),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email de l\'ami à ajouter',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        try {
                          final result = await FriendsService()
                              .searchFriendByEmail(
                                  _emailController.text);
                          setState(() {
                            _searchResult = result;
                          });
                        } catch (error) {
                          _searchResult = null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $error')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_searchResult != null) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                        '${_searchResult!['user']['firstName'] ?? 'Inconnu'} ${_searchResult!['user']['lastName'] ?? ''}'),
                    leading: CircleAvatar(
                      backgroundImage: _searchResult!['user']['picture'] == '/'
                          ? const AssetImage(
                              'assets/images/defaultProfilPicture.png')
                          : NetworkImage(
                              'http://localhost:5000${_searchResult!['user']['picture']}'),
                    ),
                    trailing: ElevatedButton(
                      onPressed: _searchResult!['canAdd'] == true &&
                              !_isRequestSent
                          ? () async {
                              try {
                                final message = await FriendsService()
                                    .sendFriendRequest(
                                        _emailController.text);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                                setState(() {
                                  _isRequestSent = true;
                                });
                                friendsSocketManager.friendSocket.emit('actuFriends', {
                                  'emails': [
                                    widget.email,
                                    _emailController.text
                                  ],
                                });
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $error')),
                                );
                              }
                            }
                          : null,
                      child: const Text('Ajouter'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
