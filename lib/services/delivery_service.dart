import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Service untuk kalkulasi estimasi ongkir & deep link ke app Gojek/Grab
class DeliveryService {
  // ============================================================
  // TARIF ESTIMASI (bisa diubah sesuai kebutuhan)
  // ============================================================
  static const double _goSendBaseFee = 12000; // Rp 12.000 base
  static const double _goSendPerKm = 2500; // Rp 2.500 / km
  static const double _grabExpressBaseFee = 10000; // Rp 10.000 base
  static const double _grabExpressPerKm = 3000; // Rp 3.000 / km

  // ============================================================
  // KALKULASI JARAK (Haversine Formula)
  // ============================================================

  /// Hitung jarak antara 2 titik koordinat dalam kilometer
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Radius bumi dalam km
    double dLat = _degToRad(lat2 - lat1);
    double dLng = _degToRad(lng2 - lng1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  // ============================================================
  // ESTIMASI ONGKOS KIRIM
  // ============================================================

  /// Estimasi tarif GoSend berdasarkan jarak (km)
  static double estimateGoSendFee(double distanceKm) {
    return _goSendBaseFee + (_goSendPerKm * distanceKm);
  }

  /// Estimasi tarif Grab Express berdasarkan jarak (km)
  static double estimateGrabExpressFee(double distanceKm) {
    return _grabExpressBaseFee + (_grabExpressPerKm * distanceKm);
  }

  /// Format harga ke Rupiah
  static String formatRupiah(double amount) {
    String formatted = amount.round().toString();
    String result = '';
    int count = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      count++;
      result = formatted[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  // ============================================================
  // NOMINATIM GEOLOCATION FALLBACKS (Free, works on Web)
  // ============================================================

  static Future<Map<String, double>?> _geocodeWithNominatim(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encodedAddress&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'ReUsea-App-V1'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return {'lat': lat, 'lng': lon};
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim geocoding failed: $e');
    }
    return null;
  }

  static Future<String> _reverseGeocodeWithNominatim(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final response = await http.get(url, headers: {'User-Agent': 'ReUsea-App-V1'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['display_name'] ?? '';
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocoding failed: $e');
    }
    return '';
  }

  // ============================================================
  // GEOCODING (Alamat ↔ Koordinat)
  // ============================================================

  /// Mendapatkan koordinat dari string alamat
  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    if (kIsWeb) {
      return await _geocodeWithNominatim(address);
    }
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return {
          'lat': locations.first.latitude,
          'lng': locations.first.longitude,
        };
      }
    } catch (e) {
      print('Gagal geocoding alamat dengan native, fallback ke Nominatim: $e');
      return await _geocodeWithNominatim(address);
    }
    return null;
  }

  /// Mendapatkan alamat dari koordinat (reverse geocoding)
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    if (kIsWeb) {
      return await _reverseGeocodeWithNominatim(lat, lng);
    }
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
    } catch (e) {
      print('Gagal reverse geocoding native, fallback ke Nominatim: $e');
      return await _reverseGeocodeWithNominatim(lat, lng);
    }
    return '';
  }

  // ============================================================
  // LOKASI GPS USER
  // ============================================================

  /// Mendapatkan posisi GPS user saat ini
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Gagal mendapatkan lokasi GPS: $e');
      return null;
    }
  }

  // ============================================================
  // DEEP LINK KE APLIKASI GOJEK / GRAB
  // ============================================================

  /// Buka aplikasi Gojek (GoSend)
  /// Deep link: gojek:// atau fallback ke Play Store jika di mobile, langsung ke Play Store jika di Web
  static Future<void> openGojekApp() async {
    final Uri playStoreUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.gojek.app&hl=id',
    );

    if (kIsWeb) {
      await launchUrl(
        playStoreUri,
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    final Uri gojekUri = Uri.parse('gojek://');
    try {
      bool launched = await launchUrl(
        gojekUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(
        playStoreUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Buka aplikasi Grab (Grab Express)
  /// Deep link: grab:// atau fallback ke Play Store jika di mobile, langsung ke Play Store jika di Web
  static Future<void> openGrabApp() async {
    final Uri playStoreUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.grabtaxi.passenger&hl=id',
    );

    if (kIsWeb) {
      await launchUrl(
        playStoreUri,
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    final Uri grabUri = Uri.parse('grab://');
    try {
      bool launched = await launchUrl(
        grabUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(
        playStoreUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
