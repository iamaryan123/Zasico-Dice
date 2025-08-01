import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<Map<String, dynamic>> authenticate(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }
}