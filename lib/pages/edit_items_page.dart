import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/database_service.dart';

class EditItemPage extends StatefulWidget {
  // Terima objek produk dan document ID dari halaman MyItems
  final Product product;
  final String productId;

  const EditItemPage({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final DatabaseService _dbService = DatabaseService();

  // Inisialisasi controller dengan data lama dari widget.product
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  final List<String> categories = ["Books", "Electronics", "Fashion"];
  late String selectedCategory;
  late String selectedLocation;

  // Penampung foto baru
  Uint8List? _newImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi data lama produk ke dalam controllers saat halaman dibuka
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price);
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );

    // Normalisasi category: disesuaikan agar cocok dengan list kategor (karena di DB Caps)
    String categoryInDb = widget.product.category.toLowerCase();
    selectedCategory = categories.firstWhere(
      (cat) => cat.toLowerCase() == categoryInDb,
      orElse: () => "Books",
    );

    selectedLocation = widget.product.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        var bytes = await image.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil gambar baru: $e")),
        );
      }
    }
  }

  // LOGIKA UTAMA: MEMPERBARUI DATA
  void _handleUpdateItem() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua kolom deskripsi barang!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Memanggil fungsi updateProduct di DatabaseService
    await _dbService.updateProduct(
      productId: widget.productId,
      name: _nameController.text.trim(),
      price: _priceController.text.trim(),
      category: selectedCategory,
      description: _descriptionController.text.trim(),
      location: selectedLocation,
      newImageBytes:
          _newImageBytes, // Kirim bytes foto BARU (bisa null jika user ga ganti foto)
      existingImageUrl: widget.product.imagePath, // Kirim URL foto LAMA
      onSuccess: () {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Data barang berhasil diperbarui."),
              backgroundColor: Colors.green,
            ),
          );
          // Kembali ke halaman My Items
          Navigator.pop(context);
        }
      },
      onError: (errorMessage) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Edit Item",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Product Photos (Klik slot UTAMA untuk mengganti)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: _buildPhotoSlot("MAIN", true),
                ),
                const SizedBox(width: 10),
                _buildPhotoSlot("+", false),
                const SizedBox(width: 10),
                _buildPhotoSlot("+", false),
              ],
            ),
            const SizedBox(height: 25),
            _buildInputLabel("Product Name"),
            _buildTextField("e.g. Almamater UNESA Size L", _nameController),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Price"),
                      _buildTextField(
                        "Rp 0",
                        _priceController,
                        keyboardType: TextInputType.number,
                        formatters: [CurrencyInputFormatter()],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Category"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 57,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFFBC8E52),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: categories.map((String cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildInputLabel("Description"),
            _buildTextField(
              "Describe your item (condition, usage time, etc.)",
              _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 15),

            _buildInputLabel("Pickup Location"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: selectedLocation,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFBC8E52),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFFBC8E52)),
                ),
                items:
                    [
                      "UNESA Lidah Wetan, Surabaya",
                      "UNESA Ketintang, Surabaya",
                    ].map((String location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLocation = newValue!;
                  });
                },
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdateItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC8E52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Slot foto dimodifikasi untuk menampilkan FOTO LAMA (URL) atau FOTO BARU (Byte)
  Widget _buildPhotoSlot(String label, bool isMain) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isMain
            ? Border.all(color: const Color(0xFFBC8E52), width: 2)
            : null,
      ),
      child: isMain
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // Prioritas 1: Tampilkan foto baru yang barusan dipilih user
              child: _newImageBytes != null
                  ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                  // Prioritas 2: Tampilkan foto lama yang sudah ada di Firebase Storage
                  : widget.product.imagePath.startsWith('http')
                  ? Image.network(widget.product.imagePath, fit: BoxFit.cover)
                  // Fallback: Tampilkan ikon placeholder
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Color(0xFFBC8E52),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFBC8E52),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Color(0xFFBC8E52)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFBC8E52),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}

// Copy kelas CurrencyInputFormatter dari sell_item_page.dart ke bagian bawah file ini
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty)
      return newValue.copyWith(
        text: 'Rp 0',
        selection: const TextSelection.collapsed(offset: 4),
      );
    final chars = cleaned.split('');
    String formatted = '';
    int count = 0;
    for (int i = chars.length - 1; i >= 0; i--) {
      formatted = chars[i] + formatted;
      count++;
      if (count % 3 == 0 && i != 0) formatted = '.$formatted';
    }
    formatted = 'Rp $formatted';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
