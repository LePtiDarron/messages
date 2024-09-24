import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/new_chat.dart';
import 'screens/participants_screen.dart';
import 'screens/add_participants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teams',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/new-chat': (context) => const NewChatScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name!.startsWith('/add-participants/')) {
          final chatId = settings.name!.substring(18);
          return MaterialPageRoute(
            builder: (context) => AddParticipantsScreen(chatId: chatId),
          );
        } else if (settings.name!.startsWith('/chat-participants/')) {
          final chatId = settings.name!.substring(19);
          return MaterialPageRoute(
            builder: (context) => ParticipantsScreen(chatId: chatId),
          );
        } else if (settings.name!.startsWith('/chat/')) {
          final chatId = settings.name!.substring(6);
          return MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId),
          );
        } else {
          return null;
        }
      },
    );
  }
}
