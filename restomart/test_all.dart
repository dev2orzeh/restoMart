import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://restomart.pk/wp-json/wc/v3/products?page=1&per_page=20&consumer_key=ck_823aab9b5cab2eba66e6751f4f5c6502fe306566&consumer_secret=cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f';
  final response = await http.get(Uri.parse(url));
  print('Status: ${response.statusCode}');
  final list = json.decode(response.body) as List;
  print('Count: ${list.length}');
}
