import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import '../../modules/orders/controllers/orders_controller.dart';

class EmailService {
  static const String _smtpUsername = 'frazliaqat1116@gmail.com'; 
  static const String _smtpPassword = 'pudposbvnnpojuue'; // Gmail App Password

  static Future<void> sendInvoiceEmail({
    required String recipientEmail,
    required OrderModel order,
    required Uint8List pdfBytes,
  }) async {
    if (_smtpUsername == 'YOUR_EMAIL@gmail.com') {
      Get.snackbar(
        'Email Setup Required',
        'Please configure your SMTP credentials in EmailService to send emails.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final smtpServer = gmail(_smtpUsername, _smtpPassword);

    String itemsHtml = '';
    double subtotal = 0;
    for (var item in order.items) {
      double itemTotal = item.price * item.quantity;
      subtotal += itemTotal;
      itemsHtml += '''
        <tr>
          <td style="padding: 8px 0; border-bottom: 1px solid #eee;">${item.quantity} x ${item.name}</td>
          <td style="text-align: right; padding: 8px 0; border-bottom: 1px solid #eee;">Rs. ${itemTotal.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }

    final htmlBody = '''
<div style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: auto;">
  <div style="text-align: center; margin-bottom: 20px;">
    <h2 style="color: #25258F; font-size: 28px; font-weight: 900; margin: 0;">RestoMart <span style="color:#FFC400;">B2B</span></h2>
  </div>
  
  <div style="text-align: center;">
    <h1 style="color: #25258F; font-size: 24px;">Hey there,</h1>
    <h2 style="color: #FFC400; font-size: 20px;">Your order is in. Here's the rundown.</h2>
    <p style="margin-top: 10px; color: #666;">Nice choice!</p>
  </div>

  <p style="text-align: center; font-size: 14px; margin: 20px 0;">Your order from <strong>RestoMart B2B</strong> has been placed. You'll get a notification on the app when it's on its way to you.</p>
  
  <h4 style="border-bottom: 1px solid #eee; padding-bottom: 8px;">Order details</h4>
  <table style="width: 100%; font-size: 14px; margin-bottom: 20px; background-color: #f9f9f9; padding: 15px; border-radius: 8px;">
    <tr>
      <td style="padding: 4px 0;"><strong>Order number</strong></td>
      <td style="text-align: right;">${order.id}</td>
    </tr>
    <tr>
      <td style="padding: 4px 0;"><strong>Order time</strong></td>
      <td style="text-align: right;">${order.date.toLocal().toString().split('.')[0]}</td>
    </tr>
    <tr>
      <td style="padding: 4px 0;"><strong>Delivery address</strong></td>
      <td style="text-align: right;">Your Registered Address</td>
    </tr>
  </table>

  <h4 style="border-bottom: 1px solid #eee; padding-bottom: 8px;">Ordered items</h4>
  <table style="width: 100%; font-size: 14px; border-collapse: collapse;">
    $itemsHtml
  </table>

  <table style="width: 100%; font-size: 14px; margin-top: 10px;">
    <tr>
      <td style="padding: 4px 0;">Subtotal</td>
      <td style="text-align: right;">Rs. ${subtotal.toStringAsFixed(2)}</td>
    </tr>
    <tr>
      <td style="padding: 4px 0;">Delivery fee</td>
      <td style="text-align: right;">Rs. ${(order.total - subtotal).toStringAsFixed(2)}</td>
    </tr>
    <tr>
      <td style="padding: 8px 0; font-weight: bold; font-size: 16px;">Order Total</td>
      <td style="text-align: right; font-weight: bold; font-size: 16px;">Rs. ${order.total.toStringAsFixed(2)}</td>
    </tr>
  </table>

  <div style="text-align: center; margin: 30px 0;">
    <a href="#" style="background-color: #FFC400; color: #25258F; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold; font-size: 16px;">Track your order</a>
  </div>
  
  <div style="text-align: center; margin-top: 30px;">
    <p style="margin: 5px 0;">Until next time,</p>
    <h3 style="color: #25258F; margin: 0;">Your RestoMart team</h3>
  </div>
  <div style="background-color: #f4f5f7; padding: 20px; text-align: center; font-size: 11px; color: #888; border-radius: 0 0 12px 12px;">
    <p style="margin: 0;">Privacy | General terms and conditions</p>
    <p style="margin: 5px 0;">RestoMart B2B, Lahore, Pakistan<br>© 2026 RestoMart</p>
  </div>
</div>
''';

    final message = Message()
      ..from = Address('ali@restomart.pk', 'RestoMart B2B')
      ..recipients.add(recipientEmail)
      ..subject = 'Your RestoMart Order #${order.id} is confirmed! (${DateTime.now().toLocal().toString().split('.')[0]})'
      ..html = htmlBody
      ..attachments.add(
        StreamAttachment(
          Stream.fromIterable([pdfBytes]),
          'application/pdf',
        )..fileName = 'RestoMart_Invoice_${order.id}.pdf',
      );

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      Get.snackbar(
        'Email Failed',
        'Could not send the invoice email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  static Future<void> sendCancellationEmail(OrderModel order, String recipientEmail) async {
    final smtpServer = gmail(_smtpUsername, _smtpPassword);

    final htmlBody = '''
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #333; padding: 20px; border: 1px solid #eee; border-radius: 12px;">
  <div style="text-align: center; margin-bottom: 20px;">
    <h2 style="color: #D32F2F; margin: 0;">Order Cancelled</h2>
  </div>
  
  <p style="font-size: 16px;">Hi there,</p>
  <p style="font-size: 16px;">Your RestoMart order <strong>${order.id}</strong> has been successfully cancelled as per your request.</p>
  <p style="font-size: 16px;">If you have already paid for this order, the refund process will be initiated shortly according to our policies.</p>
  
  <div style="text-align: center; margin-top: 30px;">
    <p style="margin: 5px 0;">Until next time,</p>
    <h3 style="color: #25258F; margin: 0;">Your RestoMart team</h3>
  </div>
</div>
''';

    final message = Message()
      ..from = Address('ali@restomart.pk', 'RestoMart B2B')
      ..recipients.add(recipientEmail)
      ..subject = 'Order Cancelled - #${order.id}'
      ..html = htmlBody;

    try {
      await send(message, smtpServer);
      Get.snackbar(
        'Email Sent',
        'Cancellation email has been sent to $recipientEmail',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      print('Cancellation email failed to send: ' + e.toString());
      Get.snackbar(
        'Email Failed',
        'Could not send the cancellation email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
