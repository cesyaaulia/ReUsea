import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> chats = [
    {
      'name': 'Ahmad Fauzi',
      'message': 'Is the Kalkulus textbook still av...',
      'time': '10:30 AM',
      'unreadCount': 2,
      'isOnline': true,
      'avatarUrl': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'name': 'Siti Aminah',
      'message': 'Sure! I can meet you at the Re...',
      'time': 'Yesterday',
      'unreadCount': 0,
      'isOnline': false,
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'name': 'Budi Santoso',
      'message': 'Check my offer for the lab co...',
      'time': '2 days ago',
      'unreadCount': 0,
      'isOnline': false,
      'avatarUrl': 'https://i.pravatar.cc/150?img=12',
    },
    {
      'name': 'Diana Putri',
      'message': 'Sent a photo',
      'time': 'Mar 12',
      'unreadCount': 0,
      'isOnline': false,
      'avatarUrl': 'https://i.pravatar.cc/150?img=9',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F9),
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (context, index) => const Divider(
          color: Colors.transparent,
          height: 10,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatTile(chat);
        },
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[300],
                backgroundImage: NetworkImage(chat['avatarUrl']),
              ),
              if (chat['isOnline'] == true)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent[400],
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF7F9F9), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chat['message'],
                  style: TextStyle(
                    color: Colors.blueGrey[300],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat['time'],
                style: TextStyle(
                  color: Colors.blueGrey[300],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              if (chat['unreadCount'] > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat['unreadCount'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
