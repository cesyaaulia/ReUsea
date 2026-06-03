import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reusea/services/auth_service.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Jual Barang",
          style: TextStyle(color: AppTheme.darkNavy, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: OceanGradientBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ilustrasi ombak / teks sambutan atas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.glowShadow(color: AppTheme.primaryBlue),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Beri Kesempatan Kedua! ♻",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Upload barang kuliahmu yang tidak terpakai agar bisa digunakan kembali oleh sesama mahasiswa UNESA.",
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
    
                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AppTheme.softShadow(color: AppTheme.primaryBlue),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.03),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =============================================
                      // SECTION: MULTI-FOTO PRODUK
                      // =============================================
                      const Text(
                        "Foto Produk",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.darkNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tambahkan hingga $maxPhotos foto (foto pertama jadi foto utama)",
                        style: const TextStyle(fontSize: 11, color: AppTheme.secondaryBlue, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      _buildPhotoGrid(),
                      const SizedBox(height: 28),
    
                      // =============================================
                      // SECTION: NAMA PRODUK
                      // =============================================
                      _buildInputLabel("Nama Produk"),
                      _buildTextField("cth. Almamater UNESA Size L", _nameController),
                      const SizedBox(height: 20),
    
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel("Kategori"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.transparent),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedCategory,
                                    dropdownColor: Colors.white,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: AppTheme.darkNavy, fontWeight: FontWeight.bold),
                                    items: categories.map((String cat) {
                                      return DropdownMenuItem<String>(
                                        value: cat,
                                        child: Text(cat),
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
                      const SizedBox(height: 20),
    
                      // =============================================
                      // SECTION: KONDISI BARANG (Baru / Bekas)
                      // =============================================
                      _buildInputLabel("Kondisi Barang"),
                      Row(
                        children: [
                          _buildConditionChip("Baru", Icons.fiber_new_outlined),
                          const SizedBox(width: 16),
                          _buildConditionChip("Bekas", Icons.recycling_outlined),
                        ],
                      ),
                      const SizedBox(height: 20),
    
                      // =============================================
                      // SECTION: DESKRIPSI
                      // =============================================
                      _buildInputLabel("Deskripsi"),
                      _buildTextField(
                        "Jelaskan kondisi barang, kelengkapan, minus, dll.",
                        _descriptionController,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
    
                      // =============================================
                      // SECTION: LOKASI PICKUP
                      // =============================================
                      _buildInputLabel("Lokasi Pengambilan"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedLocation,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.primaryBlue,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue, size: 18),
                            prefixIconConstraints: BoxConstraints(minWidth: 32),
                          ),
                          style: const TextStyle(fontSize: 13, color: AppTheme.darkNavy, fontWeight: FontWeight.bold),
                          items: [
                            "UNESA Lidah Wetan, Surabaya",
                            "UNESA Ketintang, Surabaya",
                          ].map((String location) {
                            return DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedLocation = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    
                const SizedBox(height: 32),
                
                // Submit Button
                GestureDetector(
                  onTap: _isLoading ? null : _handleUploadItem,
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: _isLoading ? null : AppTheme.primaryGradient,
                      color: _isLoading ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _isLoading ? null : AppTheme.glowShadow(color: AppTheme.primaryBlue),
                    ),
                    alignment: Alignment.center,
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
        ),
      ),
    );
  }
  
  // =============================================
  // WIDGET: GRID FOTO MULTI-SLOT (WITH ANIMATION EFFECT)
  // =============================================
  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Tampilkan semua foto yang sudah dipilih
        for (int i = 0; i < _imageBytesList.length; i++)
          _buildPhotoItem(i),
        // Tombol tambah foto (jika belum maks)
        if (_imageBytesList.length < maxPhotos)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.primaryBlue, size: 24),
                  SizedBox(height: 4),
                  Text(
                    "Tambah",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
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
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow(),
            border: isFirst
                ? Border.all(color: AppTheme.primaryBlue, width: 2)
                : Border.all(color: Colors.transparent),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isFirst ? 14 : 16),
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: const Text(
                "UTAMA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        // Tombol hapus foto (X)
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
  
  // =============================================
  // WIDGET: CHIP KONDISI BARANG (SEGMENTED CONTROL STYLE)
  // =============================================
  Widget _buildConditionChip(String label, IconData icon) {
    bool isSelected = selectedCondition == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedCondition = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.bgLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? AppTheme.glowShadow(color: AppTheme.primaryBlue)
                : null,
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppTheme.secondaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppTheme.secondaryBlue,
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
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
      ),
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
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: AppTheme.bgLight,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// Custom currency formatter tetap di bawah
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      return newValue.copyWith(
        text: 'Rp 0',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }

    final chars = cleaned.split('');
    String formatted = '';
    int count = 0;

    for (int i = chars.length - 1; i >= 0; i--) {
      formatted = chars[i] + formatted;
      count++;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }

    formatted = 'Rp $formatted';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
