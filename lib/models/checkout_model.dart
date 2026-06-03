/// Model data untuk proses checkout di ReUsea
class CheckoutData {
  final String productId;
  final String productName;
  final String productPrice;
  final String productImage;
  final String sellerId;
  final String sellerName;
  final String sellerLocation;
  final String buyerAddress;
  final double buyerLat;
  final double buyerLng;
  final double sellerLat;
  final double sellerLng;
  final String deliveryService; // "gosend" atau "grab_express"
  final double deliveryFee;
  final double distanceKm;

  CheckoutData({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLocation,
    required this.buyerAddress,
    required this.buyerLat,
    required this.buyerLng,
    required this.sellerLat,
    required this.sellerLng,
    required this.deliveryService,
    required this.deliveryFee,
    required this.distanceKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerLocation': sellerLocation,
      'buyerAddress': buyerAddress,
      'buyerLat': buyerLat,
      'buyerLng': buyerLng,
      'sellerLat': sellerLat,
      'sellerLng': sellerLng,
      'deliveryService': deliveryService,
      'deliveryFee': deliveryFee,
      'distanceKm': distanceKm,
    };
  }
}
