import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';

class RatingModal extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const RatingModal({super.key, required this.orderData});

  /// Fungsi helper untuk menampilkan modal secara praktis
  static Future<bool?> show(BuildContext context, Map<String, dynamic> orderData) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Wajib memilih salah satu opsi
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: RatingModal(orderData: orderData),
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _commentController = TextEditingController();
  
  double _rating = 5.0; // Default 5 bintang
  bool _isLoading = false;
  bool _isSuccess = false;

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      String buyerName = user.displayName ?? user.email!.split('@')[0];
      String buyerPhoto = user.photoURL ?? '';

      await _dbService.submitSellerReview(
        orderId: widget.orderData['id'] ?? '',
        sellerId: widget.orderData['sellerId'] ?? '',
        buyerId: user.uid,
        buyerName: buyerName,
        buyerPhoto: buyerPhoto,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      _successController.forward();

      // Tampilkan animasi sukses selama 1.5 detik
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.pop(context, true); // Sukses mengulas
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengirim ulasan: $e"),
            backgroundColor: AppTheme.coralPeach,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Ulasan Terkirim! 🎉",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Terima kasih sudah berbagi pengalaman. Kamu membantu menjaga keamanan komunitas ReUsea!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.secondaryBlue,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header / Maskot mini
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pop(context, false),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                color: AppTheme.primaryBlue,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Gimana pengalaman belanjamu?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Bantu mahasiswa lain dengan menilai pelayanan dari ${widget.orderData['sellerName'] ?? 'Penjual'}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Star Rating Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                double starValue = index + 1.0;
                bool isSelected = starValue <= _rating;

                return GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _rating = starValue;
                          });
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 200),
                      tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? AppTheme.sunYellow : Colors.grey.shade300,
                            size: 44,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Rating Text Indicator
            Text(
              _getRatingText(_rating),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Comment TextField Box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkNavy,
                ),
                decoration: const InputDecoration(
                  hintText: "Ceritakan pengalaman belanjamu ke mahasiswa lain...",
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            "Kirim Ulasan",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Skip Button
            if (!_isLoading)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Nanti Aja",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5.0) return "Sangat Puas! ⭐⭐⭐⭐⭐";
    if (rating >= 4.0) return "Puas! ⭐⭐⭐⭐";
    if (rating >= 3.0) return "Biasa Saja ⭐⭐⭐";
    if (rating >= 2.0) return "Kurang Puas ⭐⭐";
    return "Sangat Kecewa ⭐";
  }
}
