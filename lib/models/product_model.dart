class Product {
  final String category;
  final String name;
  final String price;
  final String imagePath;
  final String time;

  Product({
    required this.category,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.time,
  });
}

List<Product> dummyProducts = [
  Product(
    category: "BOOKS",
    name: "Buku Agama",
    price: "Rp 50.000",
    imagePath: "assets/images/agama.jpg",
    time: "1h ago",
  ),
  Product(
    category: "ELECTRONICS",
    name: "iPhone 11 64GB",
    price: "Rp 4.500k",
    imagePath: "assets/images/iphone.jpg",
    time: "5h ago",
  ),
  Product(
    category: "FASHION",
    name: "UNESA Varsity",
    price: "Rp 85.000",
    imagePath: "assets/images/varsity.jpg",
    time: "12h ago",
  ),
  Product(
    category: "ELECTRONICS",
    name: "Magic Com",
    price: "Rp 200.000",
    imagePath: "assets/images/magiccom.jpg",
    time: "1d ago",
  ),
  Product(
    category: "ELECTRONICS",
    name: "Mechanical Keyboard",
    price: "Rp 400.000",
    imagePath: "assets/images/keyboard.jpg",
    time: "3d ago",
  ),
];