import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // Timeout for requests
  static const Duration _timeout = Duration(seconds: 10);

  Future<Map<String, String>> getDetailedLocation(
      double lat, double lon) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1&accept-language=id');

      final response = await http.get(url, headers: {
        'User-Agent': 'PetaniMaju/1.0',
      }).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        return {
          'village': address['village'] ??
              address['suburb'] ??
              address['neighbourhood'] ??
              '',
          'district': address['district'] ?? address['city_district'] ?? '',
          'regency': address['county'] ?? address['city'] ?? '',
          'province': address['state'] ?? '',
          'full': _buildFullAddress(address),
        };
      }
    } catch (e) {
      // Return empty if geocoding fails or timeout
    }

    return {
      'village': '',
      'district': '',
      'regency': '',
      'province': '',
      'full': '',
    };
  }

  String _buildFullAddress(Map<String, dynamic> address) {
    List<String> parts = [];

    // Village/Desa
    String? village =
        address['village'] ?? address['suburb'] ?? address['neighbourhood'];
    if (village != null && village.isNotEmpty) {
      parts.add(village);
    }

    // District/Kecamatan
    String? district = address['district'] ?? address['city_district'];
    if (district != null && district.isNotEmpty) {
      parts.add(district);
    }

    // Regency/Kabupaten or City
    String? regency = address['county'] ?? address['city'];
    if (regency != null && regency.isNotEmpty) {
      parts.add(regency);
    }

    // Province
    String? province = address['state'];
    if (province != null && province.isNotEmpty) {
      parts.add(province);
    }

    return parts.join(', ');
  }
}
