import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;
import '../../modules/orders/controllers/orders_controller.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfInvoiceService {
  static pw.Font? _cachedArabicFont;

  static Future<pw.Font> _loadArabicFont() async {
    if (_cachedArabicFont != null) return _cachedArabicFont!;
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      _cachedArabicFont = pw.Font.ttf(fontData);
      return _cachedArabicFont!;
    } catch (e) {
      debugPrint('Error loading Arabic/Urdu font: $e');
      return pw.Font.helvetica();
    }
  }

  static String _sanitizeText(String text) {
    final clean = text
        .replaceAll('&#8217;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-');

    // Check if string contains Arabic/Urdu unicode characters (0x0600 to 0x06FF, etc.)
    final hasArabicOrUrdu = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');
    if (hasArabicOrUrdu.hasMatch(clean)) {
      try {
        // Reshape disconnected letters to proper cursive connected forms
        final reshaped = ArabicReshaper().reshape(clean);
        // Correct visual display direction using BiDi
        final visualCodes = bidi.logicalToVisual(reshaped);
        return String.fromCharCodes(visualCodes);
      } catch (e) {
        debugPrint('Arabic/Urdu reshaping error: $e');
      }
    }

    return clean;
  }

  static Future<Map<String, double>> _getLedgerInfo() async {
    double balance = 0.0;
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      if (uid != null && uid != 'guest') {
        final doc = await FirebaseFirestore.instance.collection('ledger_accounts').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
          totalDebit = (data['totalDebit'] as num?)?.toDouble() ?? 0.0;
          totalCredit = (data['totalCredit'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } catch (e) {
      print('Error fetching ledger info for PDF: $e');
    }
    return {
      'balance': balance,
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
    };
  }

  static Future<void> generateAndPrintInvoice(OrderModel order) async {
    final ByteData bytes = await rootBundle.load('assets/images/homePageLogo.webp');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);
    final ledgerData = await _getLedgerInfo();
    final arabicFont = await _loadArabicFont();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        fontFallback: [arabicFont],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, width: 140),
                      pw.SizedBox(height: 8),
                      pw.Text('Lahore, Pakistan'),
                      pw.Text('support@restomart.com'),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.Text('Order #${order.id}'),
                      pw.Text('Date: ${order.date.toLocal().toString().split(' ')[0]}'),
                      pw.Text('Payment Method: ${order.paymentMethod}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 30),
              
              // Table Header
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2))
                ),
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]
                )
              ),
              pw.SizedBox(height: 10),
              
              // Items
              ...order.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(_sanitizeText(item.name))),
                      pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 1, child: pw.Text('Rs ${item.price}', textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 1, child: pw.Text('Rs ${(item.price * item.quantity).toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ]
                  )
                );
              }),
              
              if (order.specialInstructions != null && order.specialInstructions!.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text('Special Instructions: ${order.specialInstructions}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                ),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rs ${(order.total - (order.total > 0 && order.total > order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) ? order.total - order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) : 0)).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Delivery Fee: ', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rs ${(order.total > order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) ? order.total - order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) : 0.0).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs ${order.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                ]
              ),

              pw.SizedBox(height: 20),
              
              // Customer Business Khata (Ledger Summary Box)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.grey50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text('Method: ${order.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Status: ${order.status.value}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Customer Business Khata (Ledger):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                        pw.SizedBox(height: 5),
                        // Debit (Orders)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColors.red200, width: 0.8),
                          ),
                          child: pw.Text('Orders (Debit): Rs ${ledgerData['totalDebit']!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        ),
                        pw.SizedBox(height: 4),
                        // Credit (Received)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColors.green200, width: 0.8),
                          ),
                          child: pw.Text('Received (Credit): Rs ${ledgerData['totalCredit']!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          (ledgerData['balance']! > 0)
                              ? 'Outstanding Balance (Debt): Rs ${ledgerData['balance']!.toStringAsFixed(2)}'
                              : (ledgerData['balance']! < 0)
                                  ? 'Advance Surplus: Rs ${ledgerData['balance']!.abs().toStringAsFixed(2)}'
                                  : 'Outstanding Balance: Rs 0.00',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: ledgerData['balance']! > 0 ? PdfColors.red900 : PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Text('Thank you for your business!', style: const pw.TextStyle(color: PdfColors.grey600))
              )
            ],
          );
        },
      ),
    );

    // 1. Save directly to device storage (Downloads or Documents)
    try {
      final pdfBytes = await pdf.save();
      final filename = 'RestoMart_Invoice_${order.id}.pdf';

      Directory? saveDir;
      if (Platform.isAndroid) {
        // Try Public Downloads directory first
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = await getExternalStorageDirectory();
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      if (saveDir != null) {
        final filePath = '${saveDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes, flush: true);

        Get.snackbar(
          'Invoice Downloaded',
          'Saved to Downloads ($filename)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('Direct file save fallback: $e');
    }

    // Always open clean in-app PDF preview screen so user can view, print, or download
    Get.to(() => Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        backgroundColor: const Color(0xFF25258F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PdfPreview(
        build: (format) async => pdf.save(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'RestoMart_Invoice_${order.id}.pdf',
      ),
    ));
  }

  static Future<Uint8List> generateInvoiceBytes(OrderModel order) async {
    final ByteData bytes = await rootBundle.load('assets/images/homePageLogo.webp');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);
    final ledgerData = await _getLedgerInfo();
    final arabicFont = await _loadArabicFont();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        fontFallback: [arabicFont],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(logoImage, width: 140),
                      pw.SizedBox(height: 8),
                      pw.Text('Lahore, Pakistan'),
                      pw.Text('support@restomart.com'),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.Text('Order #${order.id}'),
                      pw.Text('Date: ${order.date.toLocal().toString().split(' ')[0]}'),
                      pw.Text('Payment Method: ${order.paymentMethod}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 30),
              
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2))
                ),
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text('Item Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(flex: 1, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]
                )
              ),
              pw.SizedBox(height: 10),
              
              ...order.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(_sanitizeText(item.name))),
                      pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 1, child: pw.Text('Rs ${item.price}', textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 1, child: pw.Text('Rs ${(item.price * item.quantity).toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ]
                  )
                );
              }),
              
              if (order.specialInstructions != null && order.specialInstructions!.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 10),
                  child: pw.Text('Special Instructions: ${order.specialInstructions}', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                ),
              pw.SizedBox(height: 15),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rs ${(order.total - (order.total > 0 && order.total > order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) ? order.total - order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) : 0)).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Delivery Fee: ', style: pw.TextStyle(fontSize: 14)),
                  pw.Text('Rs ${(order.total > order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) ? order.total - order.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)) : 0.0).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
                ]
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs ${order.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                ]
              ),

              pw.SizedBox(height: 20),
              
              // Customer Business Khata (Ledger Summary Box)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.grey50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text('Method: ${order.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Status: ${order.status.value}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Customer Business Khata (Ledger):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                        pw.SizedBox(height: 5),
                        // Debit (Orders)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.red50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColors.red200, width: 0.8),
                          ),
                          child: pw.Text('Orders (Debit): Rs ${ledgerData['totalDebit']!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        ),
                        pw.SizedBox(height: 4),
                        // Credit (Received)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            border: pw.Border.all(color: PdfColors.green200, width: 0.8),
                          ),
                          child: pw.Text('Received (Credit): Rs ${ledgerData['totalCredit']!.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          (ledgerData['balance']! > 0)
                              ? 'Outstanding Balance (Debt): Rs ${ledgerData['balance']!.toStringAsFixed(2)}'
                              : (ledgerData['balance']! < 0)
                                  ? 'Advance Surplus: Rs ${ledgerData['balance']!.abs().toStringAsFixed(2)}'
                                  : 'Outstanding Balance: Rs 0.00',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: ledgerData['balance']! > 0 ? PdfColors.red900 : PdfColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              pw.Center(
                child: pw.Text('Thank you for your business!', style: const pw.TextStyle(color: PdfColors.grey600))
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrintLedgerStatement(
    String customerName,
    String customerEmail,
    String customerPhone,
    double totalDebit,
    double totalCredit,
    double balance,
    List<Map<String, dynamic>> transactions,
  ) async {
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('assets/images/homePageLogo.webp');
      final Uint8List logoBytes = bytes.buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (_) {}

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, width: 140)
                    else
                      pw.Text('RestoMart', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.SizedBox(height: 8),
                    pw.Text('Lahore, Pakistan'),
                    pw.Text('support@restomart.com'),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('BUSINESS KHATA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.Text('Statement of Account'),
                    pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 20),
            
            // Customer Info Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text(customerEmail),
                      if (customerPhone.isNotEmpty) pw.Text(customerPhone),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Account Summary:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text('Total Orders: Rs ${totalDebit.toStringAsFixed(2)}'),
                      pw.Text('Total Paid: Rs ${totalCredit.toStringAsFixed(2)}', style: const pw.TextStyle(color: PdfColors.green700)),
                      pw.SizedBox(height: 4),
                      pw.Text('Balance Due: Rs ${balance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: balance > 0 ? PdfColors.red700 : PdfColors.black)),
                    ]
                  )
                ]
              )
            ),
            pw.SizedBox(height: 30),
            
            // Table Header
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 2))
              ),
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 4, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Debit', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Credit', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ]
              )
            ),
            pw.SizedBox(height: 10),
            
            // Items
            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                alignment: pw.Alignment.center,
                child: pw.Text('No transactions recorded yet.', style: const pw.TextStyle(color: PdfColors.grey600)),
              )
            else
              ...transactions.map((txn) {
                final isDebit = txn['type'] == 'debit';
                final amount = ((txn['amount'] as num?)?.toDouble() ?? 0.0);
                String dateStr = '';
                if (txn['date'] != null) {
                  dateStr = txn['date'].toString(); 
                }
                
                return pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 1))
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 2, child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(flex: 4, child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(txn['description'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                          if (txn['paymentMethod'] != null)
                            pw.Text(txn['paymentMethod'].toString().toUpperCase(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        ]
                      )),
                      pw.Expanded(flex: 2, child: pw.Text(isDebit ? 'Rs ${amount.toStringAsFixed(2)}' : '-', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11))),
                      pw.Expanded(flex: 2, child: pw.Text(!isDebit ? 'Rs ${amount.toStringAsFixed(2)}' : '-', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11, color: PdfColors.green700))),
                    ]
                  )
                );
              }),
            
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text('Generated by RestoMart System', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10))
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'RestoMart_Statement_${customerName.replaceAll(" ", "_")}.pdf',
    );
  }
}
