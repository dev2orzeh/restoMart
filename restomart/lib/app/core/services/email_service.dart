import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import '../../modules/orders/controllers/orders_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static String get _smtpHost => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  static int get _smtpPort => int.tryParse(dotenv.env['SMTP_PORT'] ?? '465') ?? 465;
  static String get _smtpUsername => dotenv.env['SMTP_USERNAME'] ?? ''; 
  static String get _smtpPassword => dotenv.env['SMTP_PASSWORD'] ?? '';
  static String get _fromEmail => dotenv.env['SMTP_FROM_EMAIL'] ?? (_smtpUsername.isNotEmpty ? _smtpUsername : 'ali@restomart.pk');

  static SmtpServer _getSmtpServer() {
    if (_smtpHost.contains('gmail.com')) {
      return gmail(_smtpUsername, _smtpPassword);
    }
    return SmtpServer(
      _smtpHost,
      port: _smtpPort,
      ssl: _smtpPort == 465,
      username: _smtpUsername,
      password: _smtpPassword,
    );
  }

  static Future<void> sendInvoiceEmail({
    required String recipientEmail,
    required OrderModel order,
    required Uint8List pdfBytes,
  }) async {
    if (_smtpUsername.isEmpty) {
      Get.snackbar(
        'Email Credentials Missing',
        'Please set SMTP_USERNAME and SMTP_PASSWORD in your .env file.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final smtpServer = _getSmtpServer();

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
      ..from = Address(_fromEmail, 'RestoMart B2B')
      ..recipients.add(recipientEmail)
      ..subject = 'Your RestoMart Order #${order.id} is confirmed!'
      ..html = htmlBody
      ..attachments.add(
        StreamAttachment(
          Stream.fromIterable([pdfBytes]),
          'application/pdf',
        )..fileName = 'RestoMart_Invoice_${order.id}.pdf',
      );

    try {
      final sendReport = await send(message, smtpServer);
      print('Invoice Email sent successfully: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('SMTP Exception sending email: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      Get.snackbar(
        'Email Warning',
        'Invoice created, but email dispatch encountered an SMTP issue.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('General Email error: $e');
    }
  }

  static Future<void> sendCancellationEmail(OrderModel order, String recipientEmail) async {
    if (_smtpUsername.isEmpty) return;

    final smtpServer = _getSmtpServer();

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
      ..from = Address(_fromEmail, 'RestoMart B2B')
      ..recipients.add(recipientEmail)
      ..subject = 'Order Cancelled - #${order.id}'
      ..html = htmlBody;

    try {
      await send(message, smtpServer);
      Get.snackbar(
        'Email Sent',
        'Cancellation email sent to $recipientEmail',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      print('Cancellation email failed to send: $e');
    }
  }
}
