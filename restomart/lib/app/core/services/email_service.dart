import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:get/get.dart';
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
    if (_smtpUsername.isEmpty) {
      print('SMTP_USERNAME is empty; skipping direct app cancellation email.');
      return;
    }

    if (recipientEmail.isEmpty || !recipientEmail.contains('@') || recipientEmail.contains('guest@')) {
      print('Invalid recipient email ($recipientEmail); skipping cancellation email.');
      return;
    }

    final smtpServer = _getSmtpServer();

    String itemsSummary = '';
    if (order.items.isNotEmpty) {
      itemsSummary = order.items.map((i) => '${i.quantity}x ${i.name}').take(3).join(', ');
      if (order.items.length > 3) itemsSummary += ' (+${order.items.length - 3} more)';
    }

    final htmlBody = '''
<div style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: auto; border: 1px solid #eee; border-radius: 12px; overflow: hidden;">
  <div style="background-color: #25258F; padding: 24px; text-align: center;">
    <h2 style="color: #ffffff; font-size: 26px; font-weight: 900; margin: 0;">RestoMart <span style="color:#FFC400;">B2B</span></h2>
    <p style="color: #ffffff99; margin: 6px 0 0; font-size: 13px;">Order Status Update</p>
  </div>
  
  <div style="padding: 24px;">
    <div style="text-align: center; margin-bottom: 24px;">
      <span style="display: inline-block; background-color: #FFEBEE; color: #D32F2F; padding: 6px 16px; border-radius: 20px; font-weight: bold; font-size: 14px;">
        Order Cancelled
      </span>
      <h1 style="color: #25258F; font-size: 22px; margin-top: 14px;">Order #${order.id} has been cancelled</h1>
      <p style="color: #666; font-size: 14px; margin: 8px 0 0;">Your cancellation request has been processed successfully.</p>
    </div>

    <table style="width: 100%; font-size: 14px; margin-bottom: 20px; background-color: #f9f9f9; padding: 16px; border-radius: 8px;">
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Order ID:</strong></td>
        <td style="text-align: right; font-weight: bold;">#${order.id}</td>
      </tr>
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Order Date:</strong></td>
        <td style="text-align: right;">${order.date.toLocal().toString().split('.')[0]}</td>
      </tr>
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Total Amount:</strong></td>
        <td style="text-align: right; font-weight: bold; color: #D32F2F;">Rs. ${order.total.toStringAsFixed(2)}</td>
      </tr>
      ${itemsSummary.isNotEmpty ? '''
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Items:</strong></td>
        <td style="text-align: right;">$itemsSummary</td>
      </tr>
      ''' : ''}
    </table>

    <p style="font-size: 14px; color: #555; line-height: 1.5;">
      If you have already paid for this order, your refund or khata credit adjustment will be processed in accordance with our return and cancellation policies.
    </p>

    <div style="text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px;">
      <p style="margin: 0; color: #888; font-size: 13px;">Need help or have questions?</p>
      <p style="margin: 4px 0 0; color: #25258F; font-weight: bold;">support@restomart.pk | +92 300 0000000</p>
    </div>
  </div>

  <div style="background-color: #f4f5f7; padding: 16px; text-align: center; font-size: 11px; color: #888;">
    <p style="margin: 0;">RestoMart B2B, Lahore, Pakistan<br>© 2026 RestoMart</p>
  </div>
</div>
''';

    final message = Message()
      ..from = Address(_fromEmail, 'RestoMart B2B')
      ..recipients.add(recipientEmail)
      ..subject = 'Order Cancelled - #${order.id}'
      ..html = htmlBody;

    try {
      final report = await send(message, smtpServer);
      print('Cancellation email sent successfully: $report');
      Get.snackbar(
        'Cancellation Email Sent',
        'Confirmation email sent to $recipientEmail',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Cancellation email failed to send: $e');
    }
  }

  static Future<void> sendPaymentReceivedEmail({
    required String recipientEmail,
    required double amount,
    required String paymentMethod,
    required double newBalance,
    String? description,
  }) async {
    if (_smtpUsername.isEmpty) return;

    if (recipientEmail.isEmpty || !recipientEmail.contains('@') || recipientEmail.contains('guest@')) {
      return;
    }

    final smtpServer = _getSmtpServer();

    final isToPay = newBalance > 0;
    final isAdvance = newBalance < 0;
    final balanceText = isToPay
        ? 'Rs. ${newBalance.toStringAsFixed(2)} (Payable)'
        : isAdvance
            ? 'Rs. ${newBalance.abs().toStringAsFixed(2)} (Advance Credit)'
            : 'Rs. 0.00 (All Cleared)';
    final balanceColor = isToPay ? '#D32F2F' : '#2E7D32';

    final htmlBody = '''
<div style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: auto; border: 1px solid #eee; border-radius: 12px; overflow: hidden;">
  <div style="background-color: #25258F; padding: 24px; text-align: center;">
    <h2 style="color: #ffffff; font-size: 26px; font-weight: 900; margin: 0;">RestoMart <span style="color:#FFC400;">B2B</span></h2>
    <p style="color: #ffffff99; margin: 6px 0 0; font-size: 13px;">Official Payment Receipt • Business Khata</p>
  </div>
  
  <div style="padding: 24px;">
    <div style="text-align: center; margin-bottom: 24px;">
      <span style="display: inline-block; background-color: #E8F5E9; color: #2E7D32; padding: 6px 16px; border-radius: 20px; font-weight: bold; font-size: 14px;">
        Payment Received ✅
      </span>
      <h1 style="color: #25258F; font-size: 24px; margin-top: 14px;">Payment Received: Rs. ${amount.toStringAsFixed(2)}</h1>
      <p style="color: #666; font-size: 14px; margin: 8px 0 0;">This payment has been credited to your RestoMart Business Khata.</p>
    </div>

    <table style="width: 100%; font-size: 14px; margin-bottom: 20px; background-color: #f9f9f9; padding: 16px; border-radius: 8px;">
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Amount Paid:</strong></td>
        <td style="text-align: right; font-weight: bold; color: #2E7D32; font-size: 16px;">Rs. ${amount.toStringAsFixed(2)}</td>
      </tr>
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Payment Mode:</strong></td>
        <td style="text-align: right; font-weight: bold;">$paymentMethod</td>
      </tr>
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Date & Time:</strong></td>
        <td style="text-align: right;">${DateTime.now().toLocal().toString().split('.')[0]}</td>
      </tr>
      ${description != null && description.isNotEmpty ? '''
      <tr>
        <td style="padding: 6px 0; color: #666;"><strong>Description:</strong></td>
        <td style="text-align: right;">$description</td>
      </tr>
      ''' : ''}
      <tr style="border-top: 1px solid #ddd;">
        <td style="padding: 10px 0 4px; color: #333;"><strong>Updated Balance:</strong></td>
        <td style="text-align: right; font-weight: bold; font-size: 16px; color: $balanceColor; padding-top: 10px;">$balanceText</td>
      </tr>
    </table>

    <p style="font-size: 14px; color: #555; line-height: 1.5;">
      You can review your complete transaction history and download official ledger statements at any time from <strong>My Business Khata</strong> in the RestoMart app.
    </p>

    <div style="text-align: center; margin-top: 30px; border-top: 1px solid #eee; padding-top: 20px;">
      <p style="margin: 0; color: #888; font-size: 13px;">RestoMart B2B Billing Support</p>
      <p style="margin: 4px 0 0; color: #25258F; font-weight: bold;">support@restomart.pk | +92 300 0000000</p>
    </div>
  </div>

  <div style="background-color: #f4f5f7; padding: 16px; text-align: center; font-size: 11px; color: #888;">
    <p style="margin: 0;">RestoMart B2B, Lahore, Pakistan<br>© 2026 RestoMart</p>
  </div>
</div>
''';

    final message = Message()
      ..from = Address(_fromEmail, 'RestoMart B2B')
      ..recipients.add(recipientEmail)
      ..subject = 'Payment Receipt: Rs. ${amount.toStringAsFixed(0)} Credited to your Khata'
      ..html = htmlBody;

    try {
      final report = await send(message, smtpServer);
      print('Payment receipt email sent successfully: $report');
    } catch (e) {
      print('Payment receipt email error: $e');
    }
  }
}
