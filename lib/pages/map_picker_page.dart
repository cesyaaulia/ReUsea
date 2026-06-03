import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:reusea/services/delivery_service.dart';
import 'package:reusea/utils/theme.dart';

/// Halaman fullscreen map picker untuk memilih lokasi pengiriman menggunakan OpenStreetMap
class MapPickerPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapPickerPage({
    super.key,
    this.initialLat = -7.3221, // Default: Surabaya (UNESA area)
    this.initialLng = 112.7115,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  late ll.LatLng _selectedPosition;
  String _selectedAddress = 'Memuat alamat...';
  bool _isLoadingAddress = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = ll.LatLng(widget.initialLat, widget.initialLng);
    _reverseGeocode(_selectedPosition);

    // Otomatis deteksi lokasi GPS saat halaman dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCurrentLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Cek izin lokasi & dapatkan lokasi saat ini secara otomatis jika diizinkan
  Future<void> _initCurrentLocation() async {
    // Jika koordinat yang dioper bukan koordinat default Surabaya, gunakan koordinat tersebut
    if (widget.initialLat != -7.3221 || widget.initialLng != 112.7115) {
      return;
    }

    try {
      final position = await DeliveryService.getCurrentPosition();
      if (position != null && mounted) {
        final newPos = ll.LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedPosition = newPos;
        });
        _mapController.move(newPos, 16.0);
        _reverseGeocode(newPos);
      }
    } catch (e) {
      debugPrint('Gagal mendeteksi lokasi awal: $e');
    }
  }

  /// Reverse geocode: koordinat → alamat
  Future<void> _reverseGeocode(ll.LatLng position) async {
    setState(() => _isLoadingAddress = true);
    String address = await DeliveryService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        _selectedAddress = address.isNotEmpty
            ? address
            : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoadingAddress = false;
      });
    }
  }

  /// Forward geocode: alamat → koordinat, lalu pindah kamera
  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    final coords = await DeliveryService.getCoordinatesFromAddress(query);
    if (coords != null && mounted) {
      final newPos = ll.LatLng(coords['lat']!, coords['lng']!);
      setState(() {
        _selectedPosition = newPos;
        _isSearching = false;
      });
      _mapController.move(newPos, 16.0);
      _reverseGeocode(newPos);
    } else {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alamat tidak ditemukan. Coba kata kunci lain.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  /// Dialog Persetujuan Izin Lokasi
  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.primaryBlue),
                SizedBox(width: 10),
                Text(
                  'Akses Lokasi GPS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'ReUsea memerlukan akses lokasi GPS Anda untuk mendeteksi posisi saat ini secara akurat dan memindahkan peta ke lokasi Anda. Apakah Anda mengizinkan?',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Tidak',
                  style: TextStyle(
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
                child: const Text(
                  'Izinkan',
                  style: TextStyle(
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

  /// Pindah ke lokasi GPS user saat ini
  Future<void> _goToMyLocation() async {
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

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
    );

    final position = await DeliveryService.getCurrentPosition();

    if (mounted) Navigator.pop(context); // tutup loading

    if (position != null && mounted) {
      final newPos = ll.LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = newPos;
      });
      _mapController.move(newPos, 16.0);
      _reverseGeocode(newPos);
    } else {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ========================
          // OPENSTREETMAP (FLUTTER_MAP)
          // ========================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 15.0,
              onPositionChanged: (position, hasGesture) {
                _selectedPosition = position.center;
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _reverseGeocode(_selectedPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'cesyaaulia.reusea.app',
              ),
            ],
          ),

          // ========================
          // CENTER PIN (selalu di tengah layar)
          // ========================
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppTheme.softShadow(),
                    ),
                    child: const Text(
                      'Lokasi Pengiriman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.redAccent,
                    size: 46,
                  ),
                ],
              ),
            ),
          ),

          // ========================
          // TOP BAR: Back + Search
          // ========================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    // Tombol Back
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.softShadow(),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search Bar
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.softShadow(),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Cari alamat pengiriman...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.search_rounded,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    onPressed: _searchAddress,
                                  ),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchAddress(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ========================
          // MY LOCATION FAB
          // ========================
          Positioned(
            right: 16,
            bottom: 220,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow(),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: _goToMyLocation,
                tooltip: 'Lokasi saya saat ini',
              ),
            ),
          ),

          // ========================
          // BOTTOM CARD: Address + Confirm
          // ========================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const Text(
                        'ALAMAT TERPILIH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isLoadingAddress
                                ? const Text(
                                    'Memuat alamat...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  )
                                : Text(
                                    _selectedAddress,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkNavy,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Tombol Konfirmasi
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, {
                              'lat': _selectedPosition.latitude,
                              'lng': _selectedPosition.longitude,
                              'address': _selectedAddress,
                            });
                          },
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Pilih Lokasi Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
