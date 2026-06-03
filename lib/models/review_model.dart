import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String type; // 'seller', 'buyer', 'product'
  final String targetId; // ID dari entitas yang dinilai (misal sellerId)
  final String reviewerId; // ID pembeli/reviewer
  final String reviewerName;
  final String reviewerPhoto;
  final double rating;
  final String comment;
  final String orderId; // ID Transaksi untuk anti-fraud
  final DateTime createdAt;
  final int likesCount;
  final int repliesCount;
  final int reportsCount;
  final bool isReported;

  Review({
    required this.id,
    required this.type,
    required this.targetId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.rating,
    required this.comment,
    required this.orderId,
    required this.createdAt,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.reportsCount = 0,
    this.isReported = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'targetId': targetId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhoto': reviewerPhoto,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'reportsCount': reportsCount,
      'isReported': isReported,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    Timestamp? ts = map['createdAt'] as Timestamp?;
    return Review(
      id: map['id'] ?? docId,
      type: map['type'] ?? 'seller',
      targetId: map['targetId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? 'Mahasiswa UNESA',
      reviewerPhoto: map['reviewerPhoto'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      orderId: map['orderId'] ?? '',
      createdAt: ts != null ? ts.toDate() : DateTime.now(),
      likesCount: map['likesCount'] ?? 0,
      repliesCount: map['repliesCount'] ?? 0,
      reportsCount: map['reportsCount'] ?? 0,
      isReported: map['isReported'] ?? false,
    );
  }
}
