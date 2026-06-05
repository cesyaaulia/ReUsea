import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/product_model.dart';
import 'detail_page.dart';
import '../utils/page_transitions.dart';

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
  bool _isLinkSent = false;
  late String _currentUserId;
  late String _currentUserName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _currentUserId = user?.uid ?? '';
    _currentUserName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Pembeli';

    if (widget.product != null) {
      if (widget.product!.sellerId == _currentUserId) {
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
    
    await _dbService.sendMessage(
      roomId: widget.roomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: text,
    );

    _dbService.resetUnreadCount(roomId: widget.roomId, userId: _currentUserId);
  }

  void _sendProductCard(Product product) async {
    await _dbService.sendMessage(
      roomId: widget.roomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      text: '',
      productData: product.toMap(),
    );
    _dbService.resetUnreadCount(roomId: widget.roomId, userId: _currentUserId);
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
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
            backgroundColor: AppTheme.coralPeach,
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
            backgroundColor: AppTheme.coralPeach,
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
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.bgLight,
              backgroundImage: widget.peerPhoto.isNotEmpty && widget.peerPhoto.startsWith('http')
                  ? CachedNetworkImageProvider(widget.peerPhoto)
                  : null,
              child: widget.peerPhoto.isEmpty || !widget.peerPhoto.startsWith('http')
                  ? const Icon(Icons.person_rounded, size: 20, color: AppTheme.secondaryBlue)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.peerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.darkNavy,
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
              child: Column(
                children: [
                  if (widget.product != null && _showProductCard) _buildProductHeaderCard(),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _dbService.getMessagesStream(widget.roomId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: AppTheme.secondaryBlue.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Belum ada percakapan\nMulai obrolan sekarang!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.secondaryBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                  if (_suggestions.isNotEmpty) _buildSuggestionChips(),
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
                        CircularProgressIndicator(color: AppTheme.primaryBlue),
                        SizedBox(height: 16),
                        Text(
                          "Mengunggah media...",
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildProductHeaderCard() {
    final prod = widget.product!;
    final imageToShow = prod.imageUrls.isNotEmpty ? prod.imageUrls.first : prod.imagePath;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow(),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 55,
              height: 55,
              child: imageToShow.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imageToShow,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.bgLight,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : Image.asset('assets/images/profile_placeholder.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prod.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: prod.condition == 'Baru'
                        ? AppTheme.ecoTeal.withValues(alpha: 0.1)
                        : AppTheme.sunsetOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    prod.condition,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: prod.condition == 'Baru' ? AppTheme.ecoTeal : AppTheme.sunsetOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.secondaryBlue),
              ),
              const SizedBox(height: 8),
              if (!_isLinkSent)
                ElevatedButton(
                  onPressed: () {
                    _sendProductCard(prod);
                    setState(() {
                      _isLinkSent = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Kirim Link",
                    style: TextStyle(
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
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeFormatted = _formatTimestamp(timestamp);

    final productData = data['productData'] as Map<String, dynamic>?;

    if (productData != null) {
      final product = Product.fromMap(productData);
      final imageToShow = product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imagePath;
      
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                width: 250,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow(),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 6),
                        const Text(
                          "Produk yang Dibahas",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.secondaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: imageToShow.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: imageToShow,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppTheme.bgLight,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                  )
                                : Image.asset('assets/images/profile_placeholder.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product.price,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: product.condition == 'Baru'
                                      ? AppTheme.ecoTeal.withValues(alpha: 0.1)
                                      : AppTheme.sunsetOrange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.condition,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: product.condition == 'Baru' ? AppTheme.ecoTeal : AppTheme.sunsetOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8)),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            HeroFadeRoute(page: DetailPage(product: product)),
                          );
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Tampilkan Detail Produk",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primaryBlue),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  timeFormatted,
                  style: TextStyle(
                    color: AppTheme.secondaryBlue.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final hasText = text.trim().isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
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
                gradient: isMe ? AppTheme.primaryGradient : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: AppTheme.softShadow(),
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
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 220,
                            height: 220,
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 220,
                            height: 220,
                            color: Colors.grey[100],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_collection_rounded, color: Colors.white70, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  "Pesan Video",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Klik untuk memutar",
                                  style: TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                            Positioned(
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
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
                          color: isMe ? Colors.white : AppTheme.darkNavy,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                timeFormatted,
                style: TextStyle(
                  color: AppTheme.secondaryBlue.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppTheme.primaryBlue),
              tooltip: "Kirim Gambar",
              onPressed: _pickAndSendImage,
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined, color: AppTheme.primaryBlue),
              tooltip: "Kirim Video",
              onPressed: _pickAndSendVideo,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.darkNavy),
                  decoration: const InputDecoration(
                    hintText: "Tulis pesan...",
                    hintStyle: TextStyle(color: AppTheme.secondaryBlue, fontWeight: FontWeight.w500),
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
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.white),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                style: const TextStyle(color: Colors.white),
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
                icon: const Icon(Icons.close_rounded, color: Colors.white),
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
              _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                playedColor: AppTheme.sunsetOrange,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _controller.value.volume == 0 ? Icons.volume_mute_rounded : Icons.volume_up_rounded,
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
