import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import '../../modules/orders/controllers/orders_controller.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfInvoiceService {
  static Future<void> generateAndPrintInvoice(OrderModel order) async {
    final ByteData bytes = await rootBundle.load('assets/images/homePageLogo.webp');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdf = pw.Document();

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
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 40),
              
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
                      pw.Expanded(flex: 3, child: pw.Text(item.name)),
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
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs ${order.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                ]
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

    // Give user the option to Share/Save/Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'RestoMart_Invoice_${order.id}.pdf',
    );
  }

  static Future<Uint8List> generateInvoiceBytes(OrderModel order) async {
    final ByteData bytes = await rootBundle.load('assets/images/homePageLogo.webp');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdf = pw.Document();

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
                    ]
                  )
                ]
              ),
              pw.SizedBox(height: 40),
              
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
                      pw.Expanded(flex: 3, child: pw.Text(item.name)),
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
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs ${order.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                ]
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
    final ByteData bytes = await rootBundle.load('assets/images/homePageLogo.webp');
    final Uint8List logoBytes = bytes.buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

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
                    pw.Image(logoImage, width: 140),
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
                      pw.Text(customerPhone),
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
            ...transactions.map((txn) {
              final isDebit = txn['type'] == 'debit';
              final amount = (txn['amount'] ?? 0.0) as double;
              String dateStr = '';
              if (txn['date'] != null) {
                // Since this might run on client, we expect DateTime or Timestamp. 
                // Assumes we format it in the View before passing.
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
