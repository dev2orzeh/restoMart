import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String baseUrl = 'https://restomart.pk/wp-json/wc/v3';
  const String consumerKey = 'ck_823aab9b5cab2eba66e6751f4f5c6502fe306566';
  const String consumerSecret = 'cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f';

  try {
    print('Testing Categories endpoint with query params...');
    final catRes = await http.get(Uri.parse(baseUrl + '/products/categories?per_page=5&consumer_key=' + consumerKey + '&consumer_secret=' + consumerSecret));
    print('Categories Status Code: ' + catRes.statusCode.toString());
    print('Categories Response: ' + catRes.body);
    
    print('\nTesting Products endpoint with query params...');
    final prodRes = await http.get(Uri.parse(baseUrl + '/products?per_page=5&consumer_key=' + consumerKey + '&consumer_secret=' + consumerSecret));
    print('Products Status Code: ' + prodRes.statusCode.toString());
    if (prodRes.statusCode != 200) {
      print('Products Response: ' + prodRes.body);
    } else {
      print('Products Response Length: ' + prodRes.body.length.toString() + ' chars');
    }
  } catch (e, stackTrace) {
    print('Exception:');
    print(e);
    print('StackTrace:');
    print(stackTrace);
  }
}
