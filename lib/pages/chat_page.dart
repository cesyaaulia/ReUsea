import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'chat_detail_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserId;

  // Mock chats data from friend's original code
  final List<Map<String, dynamic>> _mockChats = [
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
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String timeString = '$hour:$minute';

    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      return timeString;
    }

    DateTime yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year && dateTime.month == yesterday.month && dateTime.day == yesterday.day) {
      return 'Kemarin';
    }

    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F1EE),
        body: Center(
          child: Text(
            "Silakan login terlebih dahulu.",
            style: TextStyle(fontFamily: 'Lexend', color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontFamily: 'Lexend',
            color: Color(0xFF1A2235),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF2F1EE),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getChatRoomsStream(_currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A2235),
                  ),
                );
              }

              // Jika Firestore tidak memiliki chat rooms aktif, tampilkan fallback mock chats teman
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildMockChatList();
              }

              final rooms = snapshot.data!.docs;

              // Urutkan di Dart memory berdasarkan lastMessageTime descending
              rooms.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['lastMessageTime'] as Timestamp?;
                final bTime = bData['lastMessageTime'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: rooms.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.transparent,
                  height: 10,
                ),
                itemBuilder: (context, index) {
                  final roomData = rooms[index].data() as Map<String, dynamic>;
                  
                  // Temukan peer ID (user lawan bicara)
                  List<dynamic> participants = roomData['participants'] ?? [];
                  String peerId = participants.firstWhere(
                    (p) => p != _currentUserId,
                    orElse: () => '',
                  );

                  if (peerId.isEmpty) return const SizedBox.shrink();

                  // Info Peer
                  Map<String, dynamic> names = roomData['participantNames'] ?? {};
                  Map<String, dynamic> photos = roomData['participantPhotos'] ?? {};
                  
                  String peerName = names[peerId] ?? 'Pengguna ReUsea';
                  String peerPhoto = photos[peerId] ?? '';

                  // Info Pesan Terakhir
                  String lastMessage = roomData['lastMessage'] ?? 'Belum ada pesan';
                  Timestamp? lastMessageTime = roomData['lastMessageTime'] as Timestamp?;
                  String timeFormatted = _formatTimestamp(lastMessageTime);

                  // Unread Count
                  Map<String, dynamic> unreadMap = roomData['unreadCount'] ?? {};
                  int unreadCount = unreadMap[_currentUserId] ?? 0;

                  // Kita mock online status jika nama ada di mock list untuk visualisasi menarik
                  bool isOnline = _mockChats.any((m) => m['name'] == peerName && m['isOnline'] == true);

                  return _buildChatTileFromRoom(
                    roomId: roomData['id'] ?? '',
                    peerId: peerId,
                    peerName: peerName,
                    peerPhoto: peerPhoto,
                    lastMessage: lastMessage,
                    time: timeFormatted,
                    unreadCount: unreadCount,
                    isOnline: isOnline,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // List mock chats builder
  Widget _buildMockChatList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _mockChats.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.transparent,
        height: 10,
      ),
      itemBuilder: (context, index) {
        final chat = _mockChats[index];
        return InkWell(
          onTap: () async {
            final navigator = Navigator.of(context);
            // Tampilkan loading indicator saat inisialisasi room chat mock
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1A2235),
                ),
              ),
            );

            String mockPeerId = 'mock_${chat['name'].toString().toLowerCase().replaceAll(' ', '_')}';
            String mockRoomId = _currentUserId.compareTo(mockPeerId) < 0
                ? '${_currentUserId}_$mockPeerId'
                : '${mockPeerId}_$_currentUserId';

            try {
              // Coba buat/ambil room chat di Firestore agar pesan tersimpan secara riil
              String roomId = await _dbService.getOrCreateChatRoom(
                buyerId: _currentUserId,
                buyerName: _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@')[0] ?? 'Pembeli',
                buyerPhoto: _auth.currentUser?.photoURL ?? '',
                sellerId: mockPeerId,
                sellerName: chat['name'],
                sellerPhoto: chat['avatarUrl'],
              );

              navigator.pop(); // Tutup loading

              navigator.push(
                SlideFadeRightRoute(
                  page: ChatDetailPage(
                    roomId: roomId,
                    peerId: mockPeerId,
                    peerName: chat['name'],
                    peerPhoto: chat['avatarUrl'],
                  ),
                ),
              );
            } catch (e) {
              navigator.pop(); // Tutup loading
              // Fallback langsung navigasi jika ada kendala database
              navigator.push(
                SlideFadeRightRoute(
                  page: ChatDetailPage(
                    roomId: mockRoomId,
                    peerId: mockPeerId,
                    peerName: chat['name'],
                    peerPhoto: chat['avatarUrl'],
                  ),
                ),
              );
            }
          },
          child: Container(
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
                            border: Border.all(color: const Color(0xFFF2F1EE), width: 2),
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
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['message'],
                        style: TextStyle(
                          fontFamily: 'Lexend',
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
                        fontFamily: 'Lexend',
                        color: Colors.blueGrey[300],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (chat['unreadCount'] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                        ),
                        child: Text(
                          chat['unreadCount'].toString(),
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Real room list item builder
  Widget _buildChatTileFromRoom({
    required String roomId,
    required String peerId,
    required String peerName,
    required String peerPhoto,
    required String lastMessage,
    required String time,
    required int unreadCount,
    required bool isOnline,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          SlideFadeRightRoute(
            page: ChatDetailPage(
              roomId: roomId,
              peerId: peerId,
              peerName: peerName,
              peerPhoto: peerPhoto,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: peerPhoto.isNotEmpty && peerPhoto.startsWith('http')
                      ? NetworkImage(peerPhoto)
                      : null,
                  child: peerPhoto.isEmpty || !peerPhoto.startsWith('http')
                      ? const Icon(Icons.person, size: 28, color: Colors.grey)
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF2F1EE), width: 2),
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
                    peerName,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      color: unreadCount > 0 ? const Color(0xFF0F172A) : Colors.blueGrey[300],
                      fontSize: 13,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time & Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    color: unreadCount > 0 ? const Color(0xFF1A2235) : Colors.blueGrey[300],
                    fontSize: 11,
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
