import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';
import 'package:reusea/models/review_model.dart';

class SellerProfilePage extends StatefulWidget {
  final String sellerId;
  final String fallbackName;
  final String fallbackPhoto;

  const SellerProfilePage({
    super.key,
    required this.sellerId,
    this.fallbackName = 'Mahasiswa UNESA',
    this.fallbackPhoto = '',
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final DatabaseService _dbService = DatabaseService();

  String _formatDate(DateTime date) {
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
    ];
    if (month < 1 || month > 12) return "";
    return months[month - 1];
  }

  String _formatJoinDate(Timestamp? ts) {
    if (ts == null) return "Gabung: September 2024";
    DateTime date = ts.toDate();
    return "Gabung: ${_getMonthName(date.month)} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: OceanGradientBackground(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkNavy),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  "Profil Penjual",
                  style: TextStyle(
                    color: AppTheme.darkNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
            ];
          },
          body: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.sellerId)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                );
              }

              Map<String, dynamic>? userData;
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              }

              String sellerName = userData?['name'] ?? widget.fallbackName;
              String sellerPhoto = userData?['photoUrl'] ?? widget.fallbackPhoto;
              String faculty = userData?['faculty'] ?? 'Mahasiswa UNESA';
              int solds = userData?['solds'] ?? 0;
              double averageRating = (userData?['averageRating'] ?? 0.0).toDouble();
              int totalReviews = userData?['reviewsCount'] ?? 0;
              Timestamp? joinTimestamp = userData?['createdAt']; // Assuming registration time or updated time

              return StreamBuilder<QuerySnapshot>(
                stream: _dbService.getSellerReviewsStream(widget.sellerId),
                builder: (context, reviewsSnapshot) {
                  List<Review> reviews = [];
                  Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

                  if (reviewsSnapshot.hasData) {
                    for (var doc in reviewsSnapshot.data!.docs) {
                      var data = doc.data() as Map<String, dynamic>;
                      Review review = Review.fromMap(data, doc.id);
                      reviews.add(review);

                      // Hitung distribusi bintang
                      int ratingInt = review.rating.round();
                      if (ratingInt >= 1 && ratingInt <= 5) {
                        starDistribution[ratingInt] = (starDistribution[ratingInt] ?? 0) + 1;
                      }
                    }

                    // Urutkan ulasan secara manual (in-memory) berdasarkan tanggal terbaru
                    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  }

                  // Gunakan total ulasan dari Firestore atau ulasan yang terhitung
                  int displayReviewsCount = totalReviews > reviews.length ? totalReviews : reviews.length;
                  double displayAvgRating = averageRating > 0.0 ? averageRating : _calculateAverage(reviews);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. KARTU INFORMASI UTAMA PENJUAL
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
                          ),
                          child: Column(
                            children: [
                              // Foto Profil dengan gradasi sirkular
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.oceanWaveGradient,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: Colors.white,
                                  backgroundImage: sellerPhoto.isNotEmpty ? NetworkImage(sellerPhoto) : null,
                                  child: sellerPhoto.isEmpty
                                      ? const Icon(Icons.person_rounded, size: 46, color: AppTheme.secondaryBlue)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Nama Penjual
                              Text(
                                sellerName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.darkNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Fakultas / Jurusan
                              Text(
                                faculty,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.secondaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Tanggal Gabung
                              Text(
                                _formatJoinDate(joinTimestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondaryBlue.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),

                              // Ringkasan Statistik
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn(
                                    "${displayAvgRating > 0 ? displayAvgRating.toStringAsFixed(1) : '-'}",
                                    "Bintang",
                                    icon: Icons.star_rounded,
                                    iconColor: AppTheme.sunYellow,
                                  ),
                                  _buildStatColumn(
                                    "$displayReviewsCount",
                                    "Ulasan",
                                    icon: Icons.rate_review_outlined,
                                    iconColor: AppTheme.primaryBlue,
                                  ),
                                  _buildStatColumn(
                                    "$solds",
                                    "Terjual",
                                    icon: Icons.shopping_bag_outlined,
                                    iconColor: AppTheme.ecoTeal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Badge Reputasi Penjual
                              if (displayReviewsCount > 0)
                                _buildTrustBadge(displayAvgRating)
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "🆕 Penjual Baru",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. DIAGRAM ANALYTICS RATING
                        if (displayReviewsCount > 0) ...[
                          const Text(
                            "Statistik Ulasan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Angka Bintang Besar
                                Column(
                                  children: [
                                    Text(
                                      displayAvgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.darkNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < displayAvgRating.round()
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: AppTheme.sunYellow,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "($displayReviewsCount Ulasan)",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                // Grafik Batang Distribusi
                                Expanded(
                                  child: Column(
                                    children: List.generate(5, (index) {
                                      int star = 5 - index;
                                      int count = starDistribution[star] ?? 0;
                                      double pct = reviews.isNotEmpty
                                          ? count / reviews.length
                                          : 0.0;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              "$star",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.darkNavy,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.star_rounded, color: AppTheme.sunYellow, size: 12),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: pct,
                                                  backgroundColor: const Color(0xFFF1F5F9),
                                                  color: AppTheme.sunYellow,
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 30,
                                              child: Text(
                                                "${(pct * 100).toStringAsFixed(0)}%",
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 3. DAFTAR ULASAN TERBARU
                        const Text(
                          "Ulasan Pembeli",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (reviews.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.rate_review_outlined, color: Colors.grey, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  "Belum ada ulasan untuk penjual ini.",
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return _buildReviewCard(review);
                            },
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {required IconData icon, required Color iconColor}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.darkNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.secondaryBlue,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(double rating) {
    String badgeText = "Penjual";
    LinearGradient badgeGradient;

    if (rating >= 4.8) {
      badgeText = "🏆 Penjual Terpercaya";
      badgeGradient = const LinearGradient(
        colors: [Color(0xFFFECA57), Color(0xFFFF9F43)], // Gold Gradient
      );
    } else if (rating >= 4.0) {
      badgeText = "✅ Penjual Andal";
      badgeGradient = const LinearGradient(
        colors: [Color(0xFF54A0FF), Color(0xFF2E86DE)], // Blue Gradient
      );
    } else if (rating >= 3.0) {
      badgeText = "⚠️ Penjual Biasa";
      badgeGradient = const LinearGradient(
        colors: [Color(0xFFFF9F43), Color(0xFFEE5253)], // Orange Gradient
      );
    } else {
      badgeText = "🚨 Rating Rendah";
      badgeGradient = const LinearGradient(
        colors: [Color(0xFFEE5253), Color(0xFFD32F2F)], // Red Gradient
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: badgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.glowShadow(color: badgeGradient.colors.first),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pembeli Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.bgLight,
                backgroundImage: review.reviewerPhoto.isNotEmpty ? NetworkImage(review.reviewerPhoto) : null,
                child: review.reviewerPhoto.isEmpty
                    ? const Icon(Icons.person, size: 18, color: AppTheme.secondaryBlue)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating Bintang Kanan
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.sunYellow,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          // Komentar Ulasan
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.darkNavy.withValues(alpha: 0.85),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateAverage(List<Review> list) {
    if (list.isEmpty) return 0.0;
    double sum = 0;
    for (var r in list) {
      sum += r.rating;
    }
    return sum / list.length;
  }
}
