import 'package:socket_io_client/socket_io_client.dart' as IO;

class FriendsSocketManager {
  late IO.Socket friendSocket;

  void connect(String email) {
    friendSocket = IO.io('http://localhost:5000/friends', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    friendSocket.connect();

    friendSocket.onConnect((_) {
      friendSocket.emit('register', email);
    });
  }

  void disconnect() {
    friendSocket.disconnect();
  }
}
