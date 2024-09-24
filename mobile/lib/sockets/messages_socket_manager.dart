import 'package:socket_io_client/socket_io_client.dart' as IO;

class MessagesSocketManager {
  late IO.Socket messageSocket;

  void connect(String chatId) {
    messageSocket = IO.io('http://localhost:5000/messages', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    messageSocket.connect();

    messageSocket.onConnect((_) {
      messageSocket.emit('enterChat', chatId);
    });
  }

  void disconnect() {
    messageSocket.disconnect();
  }
}
