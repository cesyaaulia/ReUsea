import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Fungsi menandai semua pesan sebagai "Terbaca" saat ditekan/dibersihkan
  void _markAllNotificationsAsRead(List<QueryDocumentSnapshot> docs) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      if (doc['receiverId'] == _currentUserId || doc['receiverId'] == 'ALL') {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE), // Tema krem figma ReUsea baru
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F1EE),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil seluruh riwayat pesan notifikasi diurutkan dari yang terbaru
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A2235)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada pemberitahuan baru.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Filter lokal untuk memisahkan notifikasi target saya dan notifikasi global 'ALL'
          var userNotifications = snapshot.data!.docs.where((doc) {
            String receiverId = doc['receiverId'] ?? '';
            return receiverId == _currentUserId || receiverId == 'ALL';
          }).toList();

          if (userNotifications.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada pemberitahuan baru.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // Tombol untuk membersihkan / menandai semua telah dibaca
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _markAllNotificationsAsRead(userNotifications),
                    icon: const Icon(
                      Icons.done_all,
                      size: 18,
                      color: Color(0xFF1A2235),
                    ),
                    label: const Text(
                      "Tandai Semua Dibaca",
                      style: TextStyle(
                        color: Color(0xFF1A2235),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: userNotifications.length,
                  itemBuilder: (context, index) {
                    var data = userNotifications[index];
                    bool isRead = data['isRead'] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.white
                            : const Color(0xFF1A2235).withValues(alpha: 0.05), // Warna navy soft jika unread
                        borderRadius: BorderRadius.circular(12),
                        border: isRead
                            ? null
                            : Border.all(
                                color: const Color(0xFF1A2235).withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: CircleAvatar(
                          backgroundColor: isRead
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1A2235).withValues(alpha: 0.1),
                          child: Icon(
                            data['title'].toString().contains('🎉') ||
                                    data['title'].toString().contains('Terjual')
                                ? Icons.shopping_bag_outlined
                                : Icons.campaign_outlined,
                            color: const Color(0xFF1A2235),
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Pemberitahuan',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            data['message'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                        onTap: () {
                          // Menandai dokumen terpilih ini sebagai terbaca saat di-klik
                          FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(data.id)
                              .update({'isRead': true});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
