import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://restomart.pk/wp-json/wc/v3/orders?consumer_key=ck_823aab9b5cab2eba66e6751f4f5c6502fe306566&consumer_secret=cs_00ed3a9685b5697cb50e61b70a004f4f36e2b99f';
  
  final payload = {
    "payment_method": "cod",
    "payment_method_title": "Cash on delivery",
    "set_paid": false,
    "billing": {
      "first_name": "Muhammad",
      "last_name": "Ali",
      "address_1": "DHA Phase 6, Main Boulevard, Lahore",
      "city": "Karachi",
      "state": "SD",
      "postcode": "75000",
      "country": "PK",
      "email": "customer@restomart.pk",
      "phone": "+923211655556"
    },
    "shipping": {
      "first_name": "Muhammad",
      "last_name": "Ali",
      "address_1": "DHA Phase 6, Main Boulevard, Lahore",
      "city": "Karachi",
      "state": "SD",
      "postcode": "75000",
      "country": "PK",
      "email": "customer@restomart.pk",
      "phone": "+923211655556"
    },
    "line_items": [
      {
        "product_id": 0,
        "name": "Dawn Burger Buns",
        "quantity": 2
      }
    ],
    "customer_note": ""
  };

  print('Sending...');
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: json.encode(payload),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
