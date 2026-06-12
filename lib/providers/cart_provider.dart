import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/database_service.dart';

class CartProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Product> _cartItems = [];
  StreamSubscription<QuerySnapshot>? _cartSubscription;
  bool _isLoading = false;

  List<Product> get cartItems => _cartItems;
  bool get isLoading => _isLoading;

  /// Mulai mendengarkan data keranjang belanja secara real-time berdasarkan userId
  void listenToCart(String userId) {
    if (userId.isEmpty) {
      _cartItems = [];
      _isLoading = false;
      _cancelSubscription();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _cancelSubscription();
    _cartSubscription = _dbService.getCartStream(userId).listen((snapshot) {
      _cartItems = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to cart: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Menambahkan barang ke keranjang
  Future<void> addToCart(String userId, Product product) async {
    await _dbService.addToCart(userId, product);
  }

  /// Menghapus barang dari keranjang
  Future<void> removeFromCart(String userId, String productId) async {
    await _dbService.removeFromCart(userId, productId);
  }

  /// Memindahkan barang dari keranjang ke wishlist
  Future<void> moveToWishlist(String userId, Product product) async {
    await _dbService.moveCartToWishlist(userId, product);
  }

  void _cancelSubscription() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
}
