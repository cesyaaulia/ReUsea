import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reusea/models/product_model.dart';
import 'package:reusea/services/database_service.dart';
import 'package:reusea/services/delivery_service.dart';
import 'package:reusea/utils/theme.dart';
import 'map_picker_page.dart';

/// Halaman Checkout — Buyer memilih alamat pengiriman & jasa pengiriman / COD
class CheckoutPage extends StatefulWidget {
  final Product product;

  const CheckoutPage({super.key, required this.product});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();

  // State
  double? _buyerLat;
  double? _buyerLng;
  double? _sellerLat;
  double? _sellerLng;
  double? _distanceKm;
  double _goSendFee = 0;
  double _grabExpressFee = 0;
  String _selectedService = 'gosend'; // default: GoSend
  bool _isLoadingLocation = false;
  bool _isPlacingOrder = false;
  bool _hasCalculatedFee = false;

  // Animasi
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    // Auto-geocode saat focus loss
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        _geocodeManualAddress();
      }
    });

    // Geocode lokasi seller dari string
    _geocodeSellerLocation();
  }

  @override
  void dispose() {
    _animController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  /// Dialog Persetujuan Izin Lokasi
  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue),
                const SizedBox(width: 10),
                Text(
                  'Akses Lokasi GPS',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'ReUsea memerlukan akses lokasi GPS Anda untuk mendeteksi posisi saat ini secara akurat dan mengisi alamat pengiriman secara otomatis. Apakah Anda mengizinkan?',
              style: GoogleFonts.lexend(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Tidak',
                  style: GoogleFonts.lexend(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Izinkan',
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Geocode lokasi seller dari string alamat
  Future<void> _geocodeSellerLocation() async {
    final coords = await DeliveryService.getCoordinatesFromAddress(
      '${widget.product.location}, Surabaya',
    );
    if (coords != null && mounted) {
      setState(() {
        _sellerLat = coords['lat'];
        _sellerLng = coords['lng'];
      });
      _recalculateIfReady();
    } else {
      setState(() {
        // Fallback: UNESA Lidah Wetan (Default kampus)
        _sellerLat = -7.3013;
        _sellerLng = 112.6738;
      });
    }
  }

  /// Hitung ulang estimasi ongkir jika kedua koordinat tersedia
  void _recalculateIfReady() {
    if (_buyerLat != null &&
        _buyerLng != null &&
        _sellerLat != null &&
        _sellerLng != null) {
      double dist = DeliveryService.calculateDistance(
        _sellerLat!,
        _sellerLng!,
        _buyerLat!,
        _buyerLng!,
      );
      setState(() {
        _distanceKm = dist;
        _goSendFee = DeliveryService.estimateGoSendFee(dist);
        _grabExpressFee = DeliveryService.estimateGrabExpressFee(dist);
        _hasCalculatedFee = true;
      });
    }
  }

  /// Buka map picker untuk pilih lokasi
  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (context) => MapPickerPage(
          initialLat: _buyerLat ?? -7.3221,
          initialLng: _buyerLng ?? 112.7115,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _buyerLat = result['lat'];
        _buyerLng = result['lng'];
        _addressController.text = result['address'] ?? '';
      });
      _recalculateIfReady();
    }
  }

  /// Gunakan lokasi GPS saat ini
  Future<void> _useCurrentLocation() async {
    final allowed = await _showLocationPermissionDialog();
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akses lokasi dibatalkan oleh pengguna.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isLoadingLocation = true);

    final position = await DeliveryService.getCurrentPosition();

    if (position != null && mounted) {
      setState(() {
        _buyerLat = position.latitude;
        _buyerLng = position.longitude;
      });

      String address = await DeliveryService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _addressController.text = address.isNotEmpty
              ? address
              : '${position.latitude}, ${position.longitude}';
          _isLoadingLocation = false;
        });
      }
      _recalculateIfReady();
    } else {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal mendapatkan lokasi. Pastikan GPS aktif & izin lokasi diberikan.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  /// Geocode alamat manual yang diinput user
  Future<void> _geocodeManualAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isLoadingLocation = true);

    final coords = await DeliveryService.getCoordinatesFromAddress(address);

    if (coords != null && mounted) {
      setState(() {
        _buyerLat = coords['lat'];
        _buyerLng = coords['lng'];
        _isLoadingLocation = false;
      });
      _recalculateIfReady();
    } else {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Alamat tidak ditemukan. Coba masukkan lebih detail atau gunakan peta.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  /// Konfirmasi handoff ke pihak ketiga
  Future<void> _showDeliveryHandoffConfirmation(
      String serviceId, String appName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(
              serviceId == 'gosend' ? Icons.two_wheeler : Icons.delivery_dining,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 10),
            Text(
              'Konfirmasi Kurir',
              style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Anda memilih pengiriman via $serviceName. Setelah mengonfirmasi pesanan, Anda akan diarahkan untuk memesan kurir di aplikasi $appName secara mandiri. Lanjutkan?',
          style: GoogleFonts.lexend(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.lexend(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Lanjutkan',
              style: GoogleFonts.lexend(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _placeOrder();
    }
  }

  String get serviceName {
    if (_selectedService == 'gosend') return 'GoSend';
    if (_selectedService == 'grab_express') return 'Grab Express';
    return 'COD (Ketemuan)';
  }

  /// Proses pemesanan
  Future<void> _placeOrder() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Validasi alamat dilewati jika memilih opsi COD
    if (_addressController.text.trim().isEmpty && _selectedService != 'cod') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan alamat pengiriman terlebih dahulu.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Validasi estimasi ongkir dilewati jika memilih opsi COD
    if (!_hasCalculatedFee && _selectedService != 'cod') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estimasi ongkir belum dihitung. Cek alamat Anda.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    double selectedFee = 0;
    String deliveryServiceName = 'COD (Ketemuan)';
    String buyerFinalAddress = 'Ketemuan Langsung (COD di Kampus)';

    if (_selectedService == 'gosend') {
      selectedFee = _goSendFee;
      deliveryServiceName = 'GoSend';
      buyerFinalAddress = _addressController.text.trim();
    } else if (_selectedService == 'grab_express') {
      selectedFee = _grabExpressFee;
      deliveryServiceName = 'Grab Express';
      buyerFinalAddress = _addressController.text.trim();
    }

    String buyerName =
        currentUser.displayName ?? currentUser.email!.split('@')[0];

    try {
      await _dbService.placeOrder(
        productId: widget.product.id,
        name: widget.product.name,
        price: widget.product.price,
        category: widget.product.category,
        description: widget.product.description,
        location: widget.product.location,
        imagePath: widget.product.imagePath,
        sellerId: widget.product.sellerId,
        sellerName: widget.product.sellerName,
        buyerId: currentUser.uid,
        buyerName: buyerName,
        buyerAddress: buyerFinalAddress,
        buyerLat: _buyerLat ?? 0,
        buyerLng: _buyerLng ?? 0,
        deliveryService: deliveryServiceName,
        deliveryFee: selectedFee,
        distanceKm: _distanceKm ?? 0,
        onSuccess: () async {
          if (mounted) {
            setState(() => _isPlacingOrder = false);
            await _showSuccessDialog();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isPlacingOrder = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pesanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Dialog sukses setelah order berhasil
  Future<void> _showSuccessDialog() async {
    if (_selectedService == 'cod') {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Pemesanan Berhasil! 🎉',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pesanan COD Anda sudah tercatat di sistem ReUsea. Silakan hubungi penjual via Chat untuk menentukan tempat dan waktu ketemuan di Kampus!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Tutup dialog
                      Navigator.pop(context); // Kembali ke halaman utama
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Selesai',
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    String serviceName = _selectedService == 'gosend'
        ? 'GoSend'
        : 'Grab Express';
    String appName = _selectedService == 'gosend' ? 'Gojek' : 'Grab';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pesanan Berhasil! 🎉',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pesananmu sudah tercatat. Buka $appName untuk memesan $serviceName dan kirimkan barangmu!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_selectedService == 'gosend') {
                      DeliveryService.openGojekApp();
                    } else {
                      DeliveryService.openGrabApp();
                    }
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    _selectedService == 'gosend'
                        ? Icons.two_wheeler
                        : Icons.delivery_dining,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Buka $appName',
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedService == 'gosend'
                        ? const Color(0xFF00880F)
                        : const Color(0xFF00B14F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'Nanti Saja',
                  style: GoogleFonts.lexend(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _parsePrice(String priceStr) {
    String cleaned = priceStr
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(' ', '');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    double productPrice = _parsePrice(widget.product.price);

    double selectedFee = 0;
    if (_selectedService == 'gosend') {
      selectedFee = _goSendFee;
    } else if (_selectedService == 'grab_express') {
      selectedFee = _grabExpressFee;
    }

    double totalPrice = productPrice + selectedFee;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: AppTheme.softShadow(),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.darkNavy,
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.lexend(
            color: AppTheme.darkNavy,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: OceanGradientBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductSummary(),
                  const SizedBox(height: 16),

                  // Alamat disembunyikan / opsional jika memilih COD kampus
                  if (_selectedService != 'cod') ...[
                    _buildAddressSection(),
                    const SizedBox(height: 16),
                  ],

                  _buildDeliveryServiceSection(),
                  const SizedBox(height: 16),
                  _buildCostSummary(productPrice, selectedFee, totalPrice),
                  const SizedBox(height: 28),
                  _buildOrderButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.product.imagePath.startsWith('http')
                ? Image.network(
                    widget.product.imagePath,
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 85,
                      height: 85,
                      color: const Color(0xFFF2F4F7),
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 85,
                    height: 85,
                    color: const Color(0xFFF2F4F7),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryBlue,
                      size: 36,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.darkNavy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.product.condition == 'Baru'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.product.condition,
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.product.condition == 'Baru'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.product.category,
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: AppTheme.secondaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.price,
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Alamat Pengiriman',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            focusNode: _addressFocusNode,
            maxLines: 2,
            style: GoogleFonts.lexend(fontSize: 14, color: AppTheme.darkNavy),
            decoration: InputDecoration(
              hintText: 'Masukkan alamat lengkap pengiriman...',
              hintStyle: GoogleFonts.lexend(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onSubmitted: (_) => _geocodeManualAddress(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoadingLocation ? null : _geocodeManualAddress,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(
                    'Cari Alamat',
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    'Pilih Peta',
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: _isLoadingLocation ? null : _useCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      : const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF2E7D32),
                          size: 20,
                        ),
                  tooltip: 'Gunakan lokasi saat ini',
                ),
              ),
            ],
          ),
          if (_buyerLat != null && _buyerLng != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Koordinat Terkunci: ${_buyerLat!.toStringAsFixed(4)}, ${_buyerLng!.toStringAsFixed(4)}',
                    style: GoogleFonts.lexend(
                      color: const Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryServiceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFFE65100),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Jasa Pengiriman',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy,
                ),
              ),
            ],
          ),
          if (_distanceKm != null && _selectedService != 'cod')
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: Text(
                'Jarak estimasi: ${_distanceKm!.toStringAsFixed(1)} km',
                style: GoogleFonts.lexend(fontSize: 12, color: AppTheme.secondaryBlue),
              ),
            ),
          const SizedBox(height: 16),

          _buildDeliveryCard(
            serviceId: 'gosend',
            serviceName: 'GoSend',
            appName: 'Gojek',
            description: 'Kurir Instan • 1-2 jam sampai',
            fee: _goSendFee,
            iconData: Icons.two_wheeler_rounded,
            brandColor: const Color(0xFF00880F),
            bgColor: const Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 12),

          _buildDeliveryCard(
            serviceId: 'grab_express',
            serviceName: 'Grab Express',
            appName: 'Grab',
            description: 'Pengiriman Ekspres • 1-2 jam sampai',
            fee: _grabExpressFee,
            iconData: Icons.delivery_dining_rounded,
            brandColor: const Color(0xFF00B14F),
            bgColor: const Color(0xFFE0F2E9),
          ),
          const SizedBox(height: 12),

          _buildDeliveryCard(
            serviceId: 'cod',
            serviceName: 'COD (Ketemuan Langsung)',
            appName: 'Kampus',
            description: 'Ketemuan langsung gratis ongkir di area UNESA',
            fee: 0,
            iconData: Icons.people_alt_rounded,
            brandColor: AppTheme.primaryBlue,
            bgColor: const Color(0xFFE8EAF6),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard({
    required String serviceId,
    required String serviceName,
    required String appName,
    required String description,
    required double fee,
    required IconData iconData,
    required Color brandColor,
    required Color bgColor,
  }) {
    bool isSelected = _selectedService == serviceId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedService = serviceId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? bgColor.withValues(alpha: 0.4)
              : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? brandColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? brandColor.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                iconData,
                color: isSelected ? brandColor : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        serviceName,
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? brandColor : AppTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          appName,
                          style: GoogleFonts.lexend(
                            fontSize: 9,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.lexend(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  serviceId == 'cod'
                      ? 'Gratis'
                      : (_hasCalculatedFee
                          ? DeliveryService.formatRupiah(fee)
                          : '—'),
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected ? brandColor : AppTheme.darkNavy,
                  ),
                ),
                if (!_hasCalculatedFee && serviceId != 'cod')
                  Text(
                    'Isi alamat dulu',
                    style: GoogleFonts.lexend(fontSize: 10, color: Colors.grey[400]),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? brandColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brandColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary(
    double productPrice,
    double selectedFee,
    double totalPrice,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF7B1FA2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ringkasan Biaya',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCostRow(
            'Harga Barang',
            DeliveryService.formatRupiah(productPrice),
          ),
          const SizedBox(height: 10),
          _buildCostRow(
            'Ongkos Kirim ($serviceName)',
            _selectedService == 'cod'
                ? 'Rp 0'
                : (_hasCalculatedFee
                    ? DeliveryService.formatRupiah(selectedFee)
                    : '—'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.darkNavy,
                ),
              ),
              Text(
                _selectedService == 'cod'
                    ? DeliveryService.formatRupiah(productPrice)
                    : (_hasCalculatedFee
                        ? DeliveryService.formatRupiah(totalPrice)
                        : '—'),
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.lexend(fontSize: 14, color: AppTheme.secondaryBlue)),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderButton() {
    String label;
    if (_selectedService == 'gosend') {
      label = 'Pesan via GoSend';
    } else if (_selectedService == 'grab_express') {
      label = 'Pesan via Grab Express';
    } else {
      label = 'Konfirmasi COD';
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isPlacingOrder
            ? null
            : () {
                if (_selectedService == 'cod') {
                  _placeOrder();
                } else {
                  String appName = _selectedService == 'gosend' ? 'Gojek' : 'Grab';
                  _showDeliveryHandoffConfirmation(_selectedService, appName);
                }
              },
        icon: _isPlacingOrder
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white),
        label: Text(
          _isPlacingOrder ? 'Memproses Pesanan...' : label,
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
