import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../orders/views/orders_view.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../favorites/views/favorites_view.dart';
import '../../auth/controllers/auth_controller.dart';
import 'edit_profile_view.dart';
import '../../ledger/views/ledger_view.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    // Foolproof initialization in case of Hot Reload instead of Hot Restart
    if (!Get.isRegistered<OrdersController>()) {
      Get.put(OrdersController(), permanent: true);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF25258F), Color(0xFF3F51B5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    children: [
                      // Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Account',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              Get.to(() => const EditProfileView());
                            },
                            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Profile Circle + Info
                      Obx(() {
                        final authController = Get.isRegistered<AuthController>() 
                            ? Get.find<AuthController>() 
                            : Get.put(AuthController());
                            
                        return Row(
                          children: [
                            // Profile Image - Tappable
                            GestureDetector(
                              onTap: () {
                                Get.snackbar(
                                  'Profile Photo',
                                  'Profile photo upload requires a backend storage bucket which will be linked soon.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.white,
                                  colorText: Colors.black87,
                                  margin: const EdgeInsets.all(16),
                                );
                              },
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: const Color(0xFFFFD54F),
                                      child: Text(
                                        authController.userName.value.isNotEmpty 
                                          ? authController.userName.value.substring(0, 1).toUpperCase() 
                                          : 'U',
                                        style: const TextStyle(
                                          color: Color(0xFF25258F),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF25258F), width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF25258F)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authController.userName.value,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authController.userEmail.value,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, color: Colors.white.withValues(alpha: 0.7), size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          authController.userPhone.value,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Repeat Last Order (Highlighted) ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  final ordersController = Get.find<OrdersController>();
                  if (ordersController.orders.isNotEmpty) {
                    ordersController.reorder(ordersController.orders.first);
                  } else {
                    Get.snackbar('No Orders', 'You do not have any past orders yet.', snackPosition: SnackPosition.BOTTOM);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFF3C4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD54F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.replay, color: Color(0xFF25258F), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Obx(() {
                          final ordersController = Get.find<OrdersController>();
                          if (ordersController.orders.isNotEmpty) {
                            final lastOrder = ordersController.orders.first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Repeat Last Order',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${lastOrder.items.fold<int>(0, (sum, item) => sum + item.quantity)} items • Rs. ${lastOrder.total.toInt()}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Repeat Last Order',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No past orders available',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            );
                          }
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25258F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Reorder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Orders & Lists ──────────────────────────────────────
            _buildSection(
              title: 'Orders & Lists',
              items: [
                _buildMenuItem(Icons.account_balance_wallet_outlined, 'Business Khata', 'View your ledger balance and history', onTap: () {
                  Get.to(() => const LedgerView());
                }),
                _buildMenuItem(Icons.shopping_bag_outlined, 'My Orders', 'View and track your orders', onTap: () {
                  Get.to(() => const OrdersView());
                }),
                _buildMenuItem(Icons.favorite_border, 'Saved Items', 'View your favorite products', onTap: () {
                  Get.to(() => const FavoritesView());
                }),
              ],
            ),
            const SizedBox(height: 12),

            // ── Account Settings ────────────────────────────────────
            _buildSection(
              title: 'Account Settings',
              items: [
                _buildMenuItem(Icons.location_on_outlined, 'Saved Addresses', 'Manage delivery locations', onTap: () {
                  _showSavedAddresses();
                }),
                _buildMenuItem(Icons.payment, 'Payment Methods', 'Manage cards and wallets'),
                _buildMenuItem(Icons.notifications_outlined, 'Notifications', 'App alert settings', onTap: () {
                  Get.bottomSheet(
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Would you like to receive order updates and promotional alerts?', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Get.back();
                                    Get.snackbar('Notifications', 'Notifications turned OFF.', snackPosition: SnackPosition.BOTTOM);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Turn Off', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.back();
                                    Get.snackbar('Notifications', 'Notifications turned ON.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25258F),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Turn On', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),

            // ── Support & About ─────────────────────────────────────
            _buildSection(
              title: 'Support',
              items: [
                _buildMenuItem(Icons.help_outline, 'Help Center', 'FAQs and customer support', onTap: () {
                  Get.to(() => const HelpCenterView());
                }),
                _buildMenuItem(Icons.info_outline, 'About RestoMart', 'Learn about us', onTap: () {
                  Get.to(() => const AboutRestoMartView());
                }),
              ],
            ),
            const SizedBox(height: 24),

            // ── Logout Button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Logout',
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      middleText: 'Are you sure you want to log out of your account?',
                      middleTextStyle: const TextStyle(color: Colors.black87),
                      backgroundColor: Colors.white,
                      radius: 12,
                      textCancel: 'Cancel',
                      cancelTextColor: Colors.grey.shade700,
                      textConfirm: 'Log Out',
                      confirmTextColor: AppColors.primary,
                      buttonColor: AppColors.accent,
                      onConfirm: () {
                        // Actually log the user out
                        final authController = Get.find<AuthController>();
                        authController.logout();
                      },
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    'Log Out',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Version 1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  void _showSavedAddresses() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Saved Addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
            const SizedBox(height: 20),
            _buildAddressCard('Karachi Kitchen - Main', 'DHA Phase 6, Main Boulevard, Lahore', true),
            const SizedBox(height: 12),
            _buildAddressCard('Karachi Kitchen - Branch', 'Gulberg III, Near Hafeez Center, Lahore', false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Color(0xFF25258F)),
                label: const Text('Add New Address', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF25258F)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAddressCard(String title, String address, bool isDefault) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefault ? const Color(0xFFF0F0FF) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDefault ? const Color(0xFF25258F) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: isDefault ? const Color(0xFF25258F) : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25258F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTextStyles.label.copyWith(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {
        Get.snackbar('Navigation', 'Navigating to $title');
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ABOUT RESTOMART SCREEN
// ═══════════════════════════════════════════════════════════════

class AboutRestoMartView extends StatelessWidget {
  const AboutRestoMartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF25258F), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text('About RestoMart', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Image.asset('assets/images/homePageLogo.webp', height: 48, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 48),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Your Trusted Partner for Quality Groceries in Lahore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF25258F), height: 1.3),
            ),
            const SizedBox(height: 16),
            Text(
              'RestoMart is your one-stop shop for a diverse range of high quality products, both online and offsite. We offer everything you need, from Packaging and Milk to Hygiene, Fragrance, Dairy, Cleaning, Chocolate, Chilli, Canned goods, Drinking Chocolate, and Beverages.\n\nOur journey is to provide top-notch products at competitive prices while ensuring exceptional customer service.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 24),

            Text(
              'Founded by Ali Bahadur in 2017, RestoMart started as a small store in Gulberg and has since grown into a trusted name in the industry. Our dedication to quality and customer satisfaction is the milestone of our success.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
            ),
            const SizedBox(height: 32),

            // Mission
            _buildInfoCard(
              icon: Icons.flag_outlined,
              title: 'Our Mission',
              body: 'To provide the highest quality grocery products and an exceptional shopping experience, ensuring convenience, affordability, and customer satisfaction in every interaction.',
            ),
            const SizedBox(height: 16),

            // Vision
            _buildInfoCard(
              icon: Icons.visibility_outlined,
              title: 'Our Vision',
              body: 'To be the leading grocery brand in Lahore, recognized for our commitment to quality, innovation, and sustainability while fostering a positive impact on our customers and the community.',
            ),
            const SizedBox(height: 32),

            // Contact Info
            const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
            const SizedBox(height: 16),
            _buildContactRow(Icons.phone, 'Call / WhatsApp', '0321-1655556 • 0321-0655555'),
            const SizedBox(height: 12),
            _buildContactRow(Icons.location_on, 'Location', '12 G Gulberg Center, Opposite Hafeez Center, Gulberg III, Lahore'),
            const SizedBox(height: 32),

            // Social Links
            const Text('Follow Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSocialIcon('assets/images/whatsapp.webp', 'WhatsApp', const Color(0xFF25D366)),
                const SizedBox(width: 12),
                _buildSocialIcon('assets/images/facebook.jpg', 'Facebook', const Color(0xFF1877F2)),
                const SizedBox(width: 12),
                _buildSocialIcon('assets/images/instagram.jpg', 'Instagram', const Color(0xFFE4405F)),
                const SizedBox(width: 12),
                _buildSocialIcon('assets/images/tiktok.png', 'TikTok', Colors.black87),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 RestoMart.pk — All Rights Reserved',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF25258F), size: 22),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF25258F), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String imagePath, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_,__,___) => Icon(Icons.link, color: color, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELP CENTER SCREEN
// ═══════════════════════════════════════════════════════════════

class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {'q': 'How do I place an order?', 'a': 'Browse products, add items to your cart, and proceed to checkout. Select Cash on Delivery and confirm your order.'},
      {'q': 'What payment methods are available?', 'a': 'We currently accept Cash on Delivery (COD), Bank Transfer, JazzCash, and EasyPaisa.'},
      {'q': 'What is the delivery time?', 'a': 'Orders placed before 2 PM are delivered the same day within Lahore. Orders after 2 PM are delivered the next business day.'},
      {'q': 'Can I cancel my order?', 'a': 'You can cancel an order within 30 minutes of placing it. After that, please contact our support team.'},
      {'q': 'What is the minimum order amount?', 'a': 'The minimum order amount is Rs. 500 for free delivery within Lahore.'},
      {'q': 'How can I contact support?', 'a': 'Call or WhatsApp us at 0321-1655556 or 0321-0655555. We are available Mon-Sat, 9 AM to 8 PM.'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF25258F), size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text('Help Center', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25258F), Color(0xFF3F51B5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Need Help?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Our support team is here for you.\nMon - Sat, 9 AM - 8 PM', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call Us'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD54F),
                          foregroundColor: const Color(0xFF25258F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQs
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
            const SizedBox(height: 16),
            ...faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C3E50))),
                children: [
                  Text(faq['a']!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                ],
              ),
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
