import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/services/database_service.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // =============================================
  // KATEGORI LENGKAP BAHASA INDONESIA
  // =============================================
  final List<String> categories = [
    "Buku",
    "Elektronik",
    "Fashion",
    "Peralatan",
    "Olahraga",
    "Kendaraan",
    "Makanan",
    "Kesehatan",
    "Hobi",
    "Lainnya",
  ];
  String selectedCategory = "Buku";
  String selectedLocation = "UNESA Lidah Wetan, Surabaya";

  // =============================================
  // KONDISI BARANG: Baru / Bekas
  // =============================================
  String selectedCondition = "Bekas";

  // =============================================
  // MULTI-FOTO (Maksimal 5 Foto)
  // =============================================
  final List<Uint8List> _imageBytesList = [];
  static const int maxPhotos = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageBytesList.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maksimal 5 foto per produk!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        var bytes = await image.readAsBytes();
        setState(() {
          _imageBytesList.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengambil gambar: $e")));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageBytesList.removeAt(index);
    });
  }

  void _handleUploadItem() async {
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

    if (_imageBytesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wajib mengunggah minimal 1 foto produk!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    String currentUserId = _authService.currentUser?.uid ?? "anonymous_user";

    await _dbService.uploadProduct(
      name: _nameController.text.trim(),
      price: _priceController.text.trim(),
      category: selectedCategory,
      description: _descriptionController.text.trim(),
      location: selectedLocation,
      sellerId: currentUserId,
      condition: selectedCondition,
      imageBytesList: _imageBytesList,
      onSuccess: () {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Selamat! Barang Anda berhasil diunggah."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      },
      onError: (errorMessage) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
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
          "Jual Barang",
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
            // =============================================
            // SECTION: MULTI-FOTO PRODUK
            // =============================================
            const Text(
              "Foto Produk",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              "Tambahkan hingga $maxPhotos foto (tap + untuk tambah)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildPhotoGrid(),
            const SizedBox(height: 25),

            // =============================================
            // SECTION: NAMA PRODUK
            // =============================================
            _buildInputLabel("Nama Produk"),
            _buildTextField("cth. Almamater UNESA Size L", _nameController),
            const SizedBox(height: 15),

            // =============================================
            // SECTION: HARGA & KATEGORI (Row)
            // =============================================
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Harga"),
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
                      _buildInputLabel("Kategori"),
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
                          isExpanded: true,
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

            // =============================================
            // SECTION: KONDISI BARANG (Baru / Bekas)
            // =============================================
            _buildInputLabel("Kondisi Barang"),
            Row(
              children: [
                _buildConditionChip("Baru", Icons.fiber_new_outlined),
                const SizedBox(width: 12),
                _buildConditionChip("Bekas", Icons.recycling_outlined),
              ],
            ),
            const SizedBox(height: 15),

            // =============================================
            // SECTION: DESKRIPSI
            // =============================================
            _buildInputLabel("Deskripsi"),
            _buildTextField(
              "Jelaskan kondisi barang, lama pemakaian, dll.",
              _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 15),

            // =============================================
            // SECTION: LOKASI PICKUP
            // =============================================
            _buildInputLabel("Lokasi Pengambilan"),
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
                onPressed: _isLoading ? null : _handleUploadItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBC8E52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Upload Barang",
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

  // =============================================
  // WIDGET: GRID FOTO MULTI-SLOT
  // =============================================
  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Tampilkan semua foto yang sudah dipilih
        for (int i = 0; i < _imageBytesList.length; i++)
          _buildPhotoItem(i),
        // Tombol tambah foto (jika belum maks)
        if (_imageBytesList.length < maxPhotos)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBC8E52).withValues(alpha: 0.5),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: Color(0xFFBC8E52), size: 28),
                  SizedBox(height: 4),
                  Text(
                    "Tambah",
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFBC8E52),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Widget untuk menampilkan satu foto + tombol hapus
  Widget _buildPhotoItem(int index) {
    bool isFirst = index == 0;
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isFirst
                ? Border.all(color: const Color(0xFFBC8E52), width: 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isFirst ? 10 : 12),
            child: Image.memory(_imageBytesList[index], fit: BoxFit.cover),
          ),
        ),
        // Badge "UTAMA" di foto pertama
        if (isFirst)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFBC8E52),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: const Text(
                "UTAMA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Tombol hapus foto (X)
        Positioned(
          top: -2,
          right: -2,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================
  // WIDGET: CHIP KONDISI BARANG
  // =============================================
  Widget _buildConditionChip(String label, IconData icon) {
    bool isSelected = selectedCondition == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedCondition = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFBC8E52) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFBC8E52)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFFBC8E52),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
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
}

// ====================================================================
// --- CLASS CUSTOM FORMATTER UNTUK OTOMATISASI RP DAN TITIK RIBUAN ---
// ====================================================================
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua karakter yang bukan angka agar perhitungan bersih
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      return newValue.copyWith(
        text: 'Rp 0',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }

    // Ubah string angka menjadi susunan list karakter
    final chars = cleaned.split('');
    String formatted = '';
    int count = 0;

    // Looping mundur untuk menyisipkan titik setiap 3 digit angka
    for (int i = chars.length - 1; i >= 0; i--) {
      formatted = chars[i] + formatted;
      count++;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }

    // Gabungkan dengan awalan Rp
    formatted = 'Rp $formatted';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
