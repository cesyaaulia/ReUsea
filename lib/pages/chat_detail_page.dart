import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/product_model.dart';

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String peerId;
  final String peerName;
  final String peerPhoto;
  final Product? product;
  final List<String>? initialSuggestions;

  const ChatDetailPage({
    super.key,
    required this.roomId,
    required this.peerId,
    required this.peerName,
    required this.peerPhoto,
    this.product,
    this.initialSuggestions,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<String> _suggestions = [];
  bool _showProductCard = true;
  late String _currentUserId;
  late String _currentUserName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _currentUserId = user?.uid ?? '';
    _currentUserName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Pembeli';

    // Inisialisasi suggestion chips secara dinamis berdasarkan peran (Buyer/Seller)
    if (widget.product != null) {
      if (widget.product!.sellerId == _currentUserId) {
        // Current user adalah SELLER
        _suggestions = [
          "Barang masih tersedia ya kak",
          "Kondisi masih bagus kak",
          "Bisa nego tipis kok kak",
          "Bisa COD di depan gerbang UNESA Lidah Wetan",
          "Bisa COD di depan gerbang UNESA Ketintang",
          "Maaf, harganya sudah pas/nett kak",
          "Sudah tidak ada minus lain kak, siap pakai",
        ];
      } else {
        // Current user adalah BUYER
        _suggestions = [
          "Barangnya masih ada nggak kak?",
          "Kondisi barangnya gimana kak?",
          "Boleh nego nggak kak?",
          "Bisa COD di sekitar UNESA Lidah Wetan?",
          "Bisa COD di sekitar UNESA Ketintang?",
          "Ada minus lain yang belum ditulis di deskripsi?",
          "Harga pasnya berapa ya kak?",
        ];
      }
    } else if (widget.initialSuggestions != null) {
      _suggestions = List<String>.from(widget.initialSuggestions!);
    }

    // Reset unread count ketika membuka chat
    _dbService.resetUnreadCount(roomId: widget.roomId, userId: _currentUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    _messageController.clear();
    
    // Kirim pesan ke Firestore
    await _dbService.sendMessage(
      roomId: widget.roomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: text,
    );

    // Reset unread count lagi untuk keamanan
    _dbService.resetUnreadCount(roomId: widget.roomId, userId: _currentUserId);
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (file == null) return;

      setState(() {
        _isUploading = true;
      });

      final Uint8List bytes = await file.readAsBytes();
      final String fileName = 'chat_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String downloadUrl = await _dbService.uploadChatFile(
        fileBytes: bytes,
        roomId: widget.roomId,
        fileName: fileName,
      );

      await _dbService.sendMessage(
        roomId: widget.roomId,
        senderId: _currentUserId,
        senderName: _currentUserName,
        text: '',
        imageUrl: downloadUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim gambar: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickAndSendVideo() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (file == null) return;

      setState(() {
        _isUploading = true;
      });

      final Uint8List bytes = await file.readAsBytes();
      final String fileName = 'chat_vid_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String downloadUrl = await _dbService.uploadChatFile(
        fileBytes: bytes,
        roomId: widget.roomId,
        fileName: fileName,
      );

      await _dbService.sendMessage(
        roomId: widget.roomId,
        senderId: _currentUserId,
        senderName: _currentUserName,
        text: '',
        videoUrl: downloadUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim video: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
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
      return 'Kemarin $timeString';
    }
    
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    return '$day/$month $timeString';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2235),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: widget.peerPhoto.isNotEmpty && widget.peerPhoto.startsWith('http')
                  ? NetworkImage(widget.peerPhoto)
                  : null,
              child: widget.peerPhoto.isEmpty || !widget.peerPhoto.startsWith('http')
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.peerName,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              color: const Color(0xFFF2F1EE),
              child: Column(
                children: [
                  // STICKY PRODUCT PREVIEW (Shopee Style)
                  if (widget.product != null && _showProductCard) _buildProductHeaderCard(),

                  // STREAM DATA PESANAN CHAT
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _dbService.getMessagesStream(widget.roomId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF1A2235),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Belum ada percakapan\nMulai obrolan sekarang!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Lexend',
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final isMe = data['senderId'] == _currentUserId;
                            return _buildMessageBubble(data, isMe);
                          },
                        );
                      },
                    ),
                  ),

                  // QUICK CHIPS ROW (Shopee Style)
                  if (_suggestions.isNotEmpty) _buildSuggestionChips(),

                  // BOTTOM CHAT INPUT FIELD
                  _buildMessageInputField(),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF1A2235),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Mengunggah media...",
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // WIDGET KARTU PRODUK STICKY DI ATAS CHAT
  Widget _buildProductHeaderCard() {
    final prod = widget.product!;
    final imageToShow = prod.imageUrls.isNotEmpty ? prod.imageUrls.first : prod.imagePath;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 55,
              height: 55,
              child: imageToShow.startsWith('http')
                  ? Image.network(
                      imageToShow,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFFF2F1EE),
                        child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                      ),
                    )
                  : Image.asset(
                      'assets/images/profile_placeholder.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFFF2F1EE),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Info Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prod.price,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFFBC8E52),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: prod.condition == 'Baru'
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prod.condition,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: prod.condition == 'Baru'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Aksi Kirim Tautan & Tutup
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _showProductCard = false;
                  });
                },
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _sendMessage("Halo, saya tertarik dengan barang ini: ${prod.name} (${prod.price})");
                  setState(() {
                    _showProductCard = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2235),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Kirim Link",
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET ROW CHIPS REKOMENDASI PERTANYAAN
  Widget _buildSuggestionChips() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final text = _suggestions[index];
          return Container(
            margin: const EdgeInsets.only(right: 8, bottom: 8, top: 4),
            child: InkWell(
              onTap: () {
                _sendMessage(text);
                setState(() {
                  _suggestions.removeAt(index);
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF1A2235).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      color: Color(0xFF1A2235),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // WIDGET BUBBLE PESAN INDIVIDUAL
  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeFormatted = _formatTimestamp(timestamp);

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasText = text.trim().isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: hasImage || hasVideo
                  ? const EdgeInsets.all(6)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1A2235) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasImage) ...[
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => ChatImagePreviewDialog(imageUrl: imageUrl),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 220,
                              height: 220,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1A2235),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 220,
                              height: 220,
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text(
                                    "Gagal memuat gambar",
                                    style: TextStyle(fontFamily: 'Lexend', fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (hasText) const SizedBox(height: 6),
                  ],
                  if (hasVideo) ...[
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => ChatVideoPlayerDialog(videoUrl: videoUrl),
                        );
                      },
                      child: Container(
                        width: 220,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_collection,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Pesan Video",
                                  style: TextStyle(
                                    fontFamily: 'Lexend',
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Klik untuk memutar",
                                  style: TextStyle(
                                    fontFamily: 'Lexend',
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (hasText) const SizedBox(height: 6),
                  ],
                  if (hasText)
                    Padding(
                      padding: hasImage || hasVideo
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                          : EdgeInsets.zero,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                timeFormatted,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET INPUT FIELD PESAN DI BAWAH LAYAR
  Widget _buildMessageInputField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: Color(0xFF1A2235)),
              tooltip: "Kirim Gambar",
              onPressed: _pickAndSendImage,
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: Color(0xFF1A2235)),
              tooltip: "Kirim Video",
              onPressed: _pickAndSendVideo,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F1EE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: const TextStyle(fontFamily: 'Lexend', fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Tulis pesan...",
                    hintStyle: TextStyle(fontFamily: 'Lexend', color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF1A2235),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// DIALOG PREVIEW FOTO CHAT
// ====================================================================
class ChatImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  const ChatImagePreviewDialog({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black87,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 64, color: Colors.white),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// DIALOG PEMUTAR VIDEO CHAT (MEMAKAI WIDGET DARI PACKAGE video_player)
// ====================================================================
class ChatVideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const ChatVideoPlayerDialog({super.key, required this.videoUrl});

  @override
  State<ChatVideoPlayerDialog> createState() => _ChatVideoPlayerDialogState();
}

class _ChatVideoPlayerDialogState extends State<ChatVideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      }).catchError((error) {
        setState(() {
          _errorMessage = 'Gagal memutar video: $error';
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  _buildControls(),
                ],
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white, fontFamily: 'Lexend'),
                textAlign: TextAlign.center,
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.amber,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _controller.value.volume == 0 ? Icons.volume_mute : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _controller.setVolume(_controller.value.volume == 0 ? 1.0 : 0.0);
              });
            },
          ),
        ],
      ),
    );
  }
}
