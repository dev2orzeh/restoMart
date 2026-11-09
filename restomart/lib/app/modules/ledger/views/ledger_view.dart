import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/ledger_controller.dart';
import '../../auth/views/login_screen.dart';
import '../../../core/services/pdf_invoice_service.dart';

class LedgerView extends StatelessWidget {
  const LedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    // If not logged in, show login prompt
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text('Business Ledger', style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Login to view your Ledger'),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Get.to(() => const LoginScreen()),
                child: const Text('Login Now', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    final controller = Get.put(LedgerController());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('My Business Khata', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // ── Top Summary Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Builder(
                builder: (context) {
                  final bal = controller.balance.value;
                  final isToPay = bal > 0;
                  final isAdvance = bal < 0;

                  final Color statusColor = isToPay
                      ? const Color(0xFFFF5252) // Red for amount to pay
                      : isAdvance
                          ? const Color(0xFF00E676) // Green for advance
                          : Colors.white;

                  final String statusLabel = isToPay
                      ? 'BALANCE TO PAY (YOU OWE)'
                      : isAdvance
                          ? 'ADVANCE BALANCE (CREDIT)'
                          : 'ALL DUES SETTLED';

                  final IconData statusIcon = isToPay
                      ? Icons.arrow_circle_up_rounded
                      : isAdvance
                          ? Icons.arrow_circle_down_rounded
                          : Icons.check_circle_outline_rounded;

                  final String displayAmount = isAdvance
                      ? 'Rs. ${NumberFormat("#,##0").format(bal.abs())}'
                      : 'Rs. ${NumberFormat("#,##0").format(bal)}';

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayAmount, 
                        style: TextStyle(
                          color: statusColor, 
                          fontSize: 38, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isToPay
                            ? 'Outstanding amount to pay'
                            : isAdvance
                                ? 'Surplus credit balance in your account'
                                : 'No pending balance',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Total Orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Rs. ${NumberFormat("#,##0").format(controller.totalDebit.value)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Container(height: 40, width: 1, color: Colors.white24),
                          Column(
                            children: [
                              const Text('Total Paid', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Rs. ${NumberFormat("#,##0").format(controller.totalCredit.value)}', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            Get.snackbar('Notice', 'Please login to download statement.', backgroundColor: Colors.white, colorText: Colors.black);
                            return;
                          }

                          Get.snackbar(
                            'Generating Statement',
                            'Please wait while your PDF statement is being prepared...',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.white,
                            colorText: const Color(0xFF25258F),
                            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF25258F)),
                            duration: const Duration(seconds: 2),
                          );

                          try {
                            final formattedTxns = controller.transactions.map((txn) {
                              return {
                                ...txn,
                                'date': txn['date'] != null ? DateFormat('MMM d, yyyy h:mm a').format((txn['date'] as Timestamp).toDate()) : 'N/A'
                              };
                            }).toList();
                            
                            await PdfInvoiceService.generateAndPrintLedgerStatement(
                              user.displayName ?? 'Customer',
                              user.email ?? '',
                              user.phoneNumber ?? '',
                              controller.totalDebit.value,
                              controller.totalCredit.value,
                              controller.balance.value,
                              formattedTxns,
                            );
                          } catch (e) {
                            Get.snackbar('Error', 'Failed to generate statement: $e', backgroundColor: Colors.red.shade50, colorText: Colors.red);
                          }
                        },
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: const Text('Download Statement', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Transactions List ──
            Expanded(
              child: controller.transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No transactions yet', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: controller.transactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final txn = controller.transactions[index];
                        final isDebit = txn['type'] == 'debit';
                        final amount = (txn['amount'] as num?)?.toDouble() ?? 0.0;
                        
                        DateTime date = DateTime.now();
                        if (txn['date'] != null) {
                          date = (txn['date'] as Timestamp).toDate();
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: isDebit ? Colors.red.shade50 : Colors.green.shade50,
                            child: Icon(
                              isDebit ? Icons.shopping_bag_outlined : Icons.account_balance_wallet_outlined,
                              color: isDebit ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                          title: Text(
                            txn['description'] ?? 'Transaction',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy • h:mm a').format(date),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isDebit ? '-' : '+'}Rs. ${NumberFormat("#,##0").format(amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDebit ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                                ),
                              ),
                              if (txn['paymentMethod'] != null)
                                Text(
                                  txn['paymentMethod'].toString().toUpperCase(),
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
