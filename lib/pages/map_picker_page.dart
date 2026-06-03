import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:reusea/services/delivery_service.dart';

/// Halaman fullscreen map picker untuk memilih lokasi pengiriman
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
  GoogleMapController? _mapController;
  late LatLng _selectedPosition;
  String _selectedAddress = 'Memuat alamat...';
  bool _isLoadingAddress = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(widget.initialLat, widget.initialLng);
    _reverseGeocode(_selectedPosition);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Reverse geocode: koordinat → alamat
  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    String address = await DeliveryService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (mounted) {
      setState(() {
        _selectedAddress =
            address.isNotEmpty ? address : '${position.latitude}, ${position.longitude}';
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
      final newPos = LatLng(coords['lat']!, coords['lng']!);
      setState(() {
        _selectedPosition = newPos;
        _isSearching = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 16),
        ),
      );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF1A2235)),
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
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2235),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Izinkan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
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
        child: CircularProgressIndicator(color: Color(0xFF1A2235)),
      ),
    );

    final position = await DeliveryService.getCurrentPosition();

    if (mounted) Navigator.pop(context); // tutup loading

    if (position != null && mounted) {
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = newPos;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 16),
        ),
      );
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
          // GOOGLE MAP
          // ========================
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              setState(() {
                _selectedPosition = position.target;
              });
            },
            onCameraIdle: () {
              _reverseGeocode(_selectedPosition);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
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
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2235),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Lokasi Pengiriman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFE53935),
                    size: 42,
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    // Tombol Back
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1A2235),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Search Bar
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari alamat...',
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
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1A2235),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.search,
                                      color: Color(0xFF1A2235),
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
            bottom: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.my_location,
                  color: Color(0xFF1A2235),
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
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Alamat Terpilih',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFE53935),
                            size: 20,
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
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tombol Konfirmasi
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, {
                              'lat': _selectedPosition.latitude,
                              'lng': _selectedPosition.longitude,
                              'address': _selectedAddress,
                            });
                          },
                          icon: const Icon(
                            Icons.check_circle,
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
                            backgroundColor: const Color(0xFF1A2235),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
