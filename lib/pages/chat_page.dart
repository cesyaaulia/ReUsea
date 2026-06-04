import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/page_transitions.dart';
import 'package:reusea/utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        body: Center(
          child: Text(
            "Silakan login terlebih dahulu.",
            style: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OceanGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Custom
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 15, 20, 10),
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        color: AppTheme.darkNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chat List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _dbService.getChatRoomsStream(_currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final rooms = snapshot.data!.docs;

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
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                          itemCount: rooms.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final roomData = rooms[index].data() as Map<String, dynamic>;
                            
                            List<dynamic> participants = roomData['participants'] ?? [];
                            String peerId = participants.firstWhere(
                              (p) => p != _currentUserId,
                              orElse: () => '',
                            );

                            if (peerId.isEmpty) return const SizedBox.shrink();

                            Map<String, dynamic> names = roomData['participantNames'] ?? {};
                            Map<String, dynamic> photos = roomData['participantPhotos'] ?? {};
                            
                            String peerName = names[peerId] ?? 'Pengguna ReUsea';
                            String peerPhoto = photos[peerId] ?? '';

                            String lastMessage = roomData['lastMessage'] ?? 'Belum ada pesan';
                            Timestamp? lastMessageTime = roomData['lastMessageTime'] as Timestamp?;
                            String timeFormatted = _formatTimestamp(lastMessageTime);

                            Map<String, dynamic> unreadMap = roomData['unreadCount'] ?? {};
                            int unreadCount = unreadMap[_currentUserId] ?? 0;

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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "💬",
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              "Belum ada obrolan",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Mulai chat dengan penjual untuk membeli barang preloved!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryBlue,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: ListTile(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.bgLight,
              backgroundImage: peerPhoto.isNotEmpty && peerPhoto.startsWith('http')
                  ? CachedNetworkImageProvider(peerPhoto)
                  : null,
              child: peerPhoto.isEmpty || !peerPhoto.startsWith('http')
                  ? const Icon(Icons.person_rounded, size: 26, color: AppTheme.secondaryBlue)
                  : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppTheme.ecoTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          peerName,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
            fontSize: 15,
            color: AppTheme.darkNavy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lastMessage,
            style: TextStyle(
              color: unreadCount > 0 ? AppTheme.darkNavy : AppTheme.secondaryBlue.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                color: unreadCount > 0 ? AppTheme.primaryBlue : AppTheme.secondaryBlue.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.coralPeach,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppTheme.glowShadow(color: AppTheme.coralPeach),
                ),
                constraints: const BoxConstraints(minWidth: 20),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
