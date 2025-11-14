import 'dart:convert';
import 'package:http/http.dart' as http;

class N8nClient {
  static const endpoint = "https://TWÓJ-N8N-URL/log"; // <-- ustaw swój

  static Future<void> logEvent(Map<String, dynamic> data) async {
    try {
      await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );
    } catch (_) {}
  }
}
