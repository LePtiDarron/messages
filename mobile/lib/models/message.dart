class Message {
  final String content;
  final DateTime date;
  final String type;
  final String senderName;
  final String senderEmail;
  final String senderPicture;

  Message({
    required this.content,
    required this.date,
    required this.type,
    required this.senderName,
    required this.senderEmail,
    required this.senderPicture,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      senderPicture: json['senderPicture'],
    );
  }
}
