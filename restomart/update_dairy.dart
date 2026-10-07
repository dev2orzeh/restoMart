import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://restomart.pk/wp-json/wc/v3/products/36134?consumer_key=ck_823aab9b5cab2eba66e6751f4f5c6502fe306566&consumer_secret=cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f';
  
  final body = json.encode({
    'categories': [
      {'id': 40} // Chocolates
    ]
  });

  final response = await http.put(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  print('Update Status: ${response.statusCode}');
}
