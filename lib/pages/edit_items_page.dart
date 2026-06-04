import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/utils/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  late String selectedCategory;
  late String selectedLocation;
  late String selectedCondition;

  // =============================================
  // NEW: TIPE PRODUK & COD POINT
  // =============================================
  late String selectedType; // "Dijual" atau "Donasi"
  
  final List<String> campuses = [
    "UNESA Lidah Wetan",
    "UNESA Ketintang",
    "UNESA Magetan",
    "UNESA Kampus 5 Mojokerto",
    "UNESA Kampus 6 Pacet",
  ];
  late String selectedCampus;
  
  final Map<String, List<String>> campusCodPoints = {
    "UNESA Lidah Wetan": [
      "Foodcourt UNESA Lidah Wetan",
      "Gedung Fakultas Vokasi",
      "Perpustakaan UNESA",
      "GOR UNESA",
      "Pakuwon Mall",
      "Lenmarc Mall"
    ],
    "UNESA Ketintang": [
      "Foodcourt UNESA Ketintang",
      "Gedung Rektorat",
      "Perpustakaan Pusat",
      "Gedung Fakultas",
      "Royal Plaza",
      "City of Tomorrow"
    ],
    "UNESA Magetan": [
      "Area Kampus Utama",
      "Kantin Kampus",
      "Alun-Alun Magetan"
    ],
    "UNESA Kampus 5 Mojokerto": [
      "Area Kampus Utama",
      "Kantin Kampus"
    ],
    "UNESA Kampus 6 Pacet": [
      "Area Kampus Utama",
      "Kantin Kampus"
    ],
  };
  late String selectedCodPoint;
  
  final Map<String, String> codPointCrowdLevels = {
    "Foodcourt UNESA Lidah Wetan": "Ramai",
    "Gedung Fakultas Vokasi": "Sedang",
    "Perpustakaan UNESA": "Sedang",
    "GOR UNESA": "Sepi",
    "Pakuwon Mall": "Ramai",
    "Lenmarc Mall": "Sepi",
    "Foodcourt UNESA Ketintang": "Ramai",
    "Gedung Rektorat": "Sedang",
    "Perpustakaan Pusat": "Sedang",
    "Gedung Fakultas": "Sedang",
    "Royal Plaza": "Ramai",
    "City of Tomorrow": "Ramai",
    "Area Kampus Utama": "Sedang",
    "Kantin Kampus": "Ramai",
    "Alun-Alun Magetan": "Ramai",
  };

  // =============================================
  // MULTI-FOTO: Existing URLs + New bytes
  // =============================================
  List<String> _existingImageUrls = [];
  final List<Uint8List> _newImageBytesList = [];
  static const int maxPhotos = 5;
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

    // Normalisasi category: disesuaikan agar cocok dengan list kategori
    String categoryInDb = widget.product.category.toLowerCase();
    selectedCategory = categories.firstWhere(
      (cat) => cat.toLowerCase() == categoryInDb,
      orElse: () => "Lainnya",
    );

    selectedLocation = widget.product.location;
    selectedCondition = widget.product.condition;
    selectedType = widget.product.productType;

    // Parse location
    String loc = widget.product.location;
    if (loc.contains(" - ")) {
      var parts = loc.split(" - ");
      selectedCampus = parts[0];
      selectedCodPoint = parts[1];
    } else {
      if (loc.toLowerCase().contains("ketintang")) {
        selectedCampus = "UNESA Ketintang";
      } else if (loc.toLowerCase().contains("magetan")) {
        selectedCampus = "UNESA Magetan";
      } else if (loc.toLowerCase().contains("mojokerto")) {
        selectedCampus = "UNESA Kampus 5 Mojokerto";
      } else if (loc.toLowerCase().contains("pacet")) {
        selectedCampus = "UNESA Kampus 6 Pacet";
      } else {
        selectedCampus = "UNESA Lidah Wetan";
      }

      // Pastikan selectedCodPoint ada di lists
      var list = campusCodPoints[selectedCampus] ?? [];
      selectedCodPoint = list.firstWhere(
        (p) => loc.toLowerCase().contains(p.toLowerCase()) || p.toLowerCase().contains(loc.toLowerCase()),
        orElse: () => list.isNotEmpty ? list.first : "Area Kampus Utama",
      );
    }

    // Load existing image URLs dari produk
    _existingImageUrls = List<String>.from(widget.product.imageUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _totalPhotos => _existingImageUrls.length + _newImageBytesList.length;

  Future<void> _pickImage() async {
    if (_totalPhotos >= maxPhotos) {
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
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );

      if (image != null) {
        var bytes = await image.readAsBytes();
        setState(() {
          _newImageBytesList.add(bytes);
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

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageBytesList.removeAt(index);
    });
  }

  void _handleUpdateItem() async {
    if (_nameController.text.trim().isEmpty ||
        (selectedType == "Dijual" && _priceController.text.trim().isEmpty) ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi semua kolom deskripsi barang!"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_existingImageUrls.isEmpty && _newImageBytesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wajib memiliki minimal 1 foto produk!"),
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
      price: selectedType == "Donasi" ? "Gratis" : _priceController.text.trim(),
      category: selectedCategory,
      description: _descriptionController.text.trim(),
      location: selectedLocation,
      condition: selectedCondition,
      newImageBytesList:
          _newImageBytesList.isNotEmpty ? _newImageBytesList : null,
      existingImageUrls: _existingImageUrls,
      productType: selectedType,
      campus: selectedCampus,
      codPoint: selectedCodPoint,
      codCrowdLevel: codPointCrowdLevels[selectedCodPoint] ?? "Sedang",
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Edit Barang",
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
                        "Perbarui Barang Jualan! 🌊",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Ubah detail foto, harga, atau deskripsi barang untuk mempermudah pembeli menemukan barangmu.",
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
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
                      const Text(
                        "Foto Produk",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.darkNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Maksimal $maxPhotos foto. Tap + untuk tambah, X untuk hapus.",
                        style: const TextStyle(fontSize: 11, color: AppTheme.secondaryBlue, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      _buildPhotoGrid(),
                      const SizedBox(height: 28),
                      _buildInputLabel("Nama Produk"),
                      _buildTextField("cth. Almamater UNESA Size L", _nameController),
                      const SizedBox(height: 20),
                      // =============================================
                      // SECTION: TIPE PRODUK
                      // =============================================
                      _buildInputLabel("Tipe Produk"),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedType = "Dijual";
                                  _priceController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: selectedType == "Dijual" ? AppTheme.primaryGradient : null,
                                  color: selectedType == "Dijual" ? null : AppTheme.bgLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "Dijual",
                                  style: TextStyle(
                                    color: selectedType == "Dijual" ? Colors.white : AppTheme.secondaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedType = "Donasi";
                                  _priceController.text = "Gratis";
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: selectedType == "Donasi" ? AppTheme.oceanWaveGradient : null,
                                  color: selectedType == "Donasi" ? null : AppTheme.bgLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "🎁 Donasi / Titip",
                                  style: TextStyle(
                                    color: selectedType == "Donasi" ? Colors.white : AppTheme.secondaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                                  selectedType == "Donasi" ? "Gratis" : "Rp 0",
                                  _priceController,
                                  enabled: selectedType != "Donasi",
                                  keyboardType: TextInputType.number,
                                  formatters: selectedType != "Donasi" ? [CurrencyInputFormatter()] : null,
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
                      // SECTION: KONDISI BARANG
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
                      // SECTION: LOKASI PICKUP DROPDOWNS
                      // =============================================
                      _buildInputLabel("Kampus Pengambilan"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCampus,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.primaryBlue,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.school_rounded, color: AppTheme.primaryBlue, size: 18),
                            prefixIconConstraints: BoxConstraints(minWidth: 32),
                          ),
                          style: const TextStyle(fontSize: 13, color: AppTheme.darkNavy, fontWeight: FontWeight.bold),
                          items: campuses.map((String campus) {
                            return DropdownMenuItem<String>(
                              value: campus,
                              child: Text(campus),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCampus = newValue!;
                              selectedCodPoint = campusCodPoints[selectedCampus]!.first;
                              selectedLocation = "$selectedCampus - $selectedCodPoint";
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildInputLabel("📍 Rekomendasi Titik COD"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCodPoint,
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
                          items: campusCodPoints[selectedCampus]!.map((String pt) {
                            return DropdownMenuItem<String>(
                              value: pt,
                              child: Text(pt),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCodPoint = newValue!;
                              selectedLocation = "$selectedCampus - $selectedCodPoint";
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Crowd Level & Safety Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people_rounded, size: 16, color: AppTheme.primaryBlue),
                                const SizedBox(width: 8),
                                const Text(
                                  "Estimasi Keramaian: ",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (codPointCrowdLevels[selectedCodPoint] == "Ramai"
                                        ? Colors.redAccent.withValues(alpha: 0.1)
                                        : (codPointCrowdLevels[selectedCodPoint] == "Sedang"
                                            ? Colors.orangeAccent.withValues(alpha: 0.1)
                                            : Colors.green.withValues(alpha: 0.1))),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    codPointCrowdLevels[selectedCodPoint] ?? "Sedang",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (codPointCrowdLevels[selectedCodPoint] == "Ramai"
                                          ? Colors.redAccent
                                          : (codPointCrowdLevels[selectedCodPoint] == "Sedang"
                                              ? Colors.orangeAccent
                                              : Colors.green)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.shield_outlined, size: 16, color: AppTheme.ecoTeal),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Tips Keamanan: Lakukan COD di tempat ramai, cek kondisi barang secara teliti sebelum membayar, dan utamakan area kampus.",
                                    style: TextStyle(fontSize: 10, color: AppTheme.secondaryBlue, height: 1.4, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _isLoading ? null : _handleUpdateItem,
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
                            "Simpan Perubahan",
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

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (int i = 0; i < _existingImageUrls.length; i++)
          _buildExistingPhotoItem(i),
        for (int i = 0; i < _newImageBytesList.length; i++)
          _buildNewPhotoItem(i),
        if (_totalPhotos < maxPhotos)
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

  Widget _buildExistingPhotoItem(int index) {
    bool isFirst = index == 0 && _existingImageUrls.isNotEmpty;
    String url = _existingImageUrls[index];

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
            child: url.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: url,
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
                : const Icon(Icons.image, color: Colors.grey),
          ),
        ),
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
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeExistingImage(index),
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

  Widget _buildNewPhotoItem(int index) {
    bool isFirst = _existingImageUrls.isEmpty && index == 0;

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
            child: Image.memory(_newImageBytesList[index], fit: BoxFit.cover),
          ),
        ),
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
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeNewImage(index),
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
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      enabled: enabled,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: enabled ? AppTheme.darkNavy : AppTheme.secondaryBlue,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: enabled ? AppTheme.bgLight : AppTheme.bgLight.withValues(alpha: 0.5),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
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
      if (count % 3 == 0 && i != 0) formatted = '.$formatted';
    }
    formatted = 'Rp $formatted';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
