import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> predictCarPrice() async {
    final response = await http.post(
      Uri.parse('$baseUrl/price/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vehicle_type': 'car',
        'features': {
          'Brand': 'AUDI',
          'Model': 'A1',
          'YOM': 2016,
          'Engine (cc)': 990,
          'Gear': 'Automatic',
          'Fuel Type': 'Petrol',
          'Milage(KM)': 99000,
          'Town': 'Gampaha',
          'Leasing': 'No Leasing',
          'Condition': 'USED',
          'AIR CONDITION': 'Available',
          'POWER STEERING': 'Available',
          'POWER MIRROR': 'Available',
          'POWER WINDOW': 'Available'
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> predictBikePrice() async {
    final response = await http.post(
      Uri.parse('$baseUrl/price/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vehicle_type': 'bike',
        'features': {
          'name': 'Honda CB Hornet 160R',
          'year': 2019,
          'seller_type': 'Individual',
          'owner': '1st owner',
          'km_driven': 18000,
          'ex_showroom_price': 90000
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}