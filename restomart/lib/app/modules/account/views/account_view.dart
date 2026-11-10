import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../orders/views/orders_view.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../favorites/views/favorites_view.dart';
import '../../auth/controllers/auth_controller.dart';
import 'edit_profile_view.dart';
import '../../ledger/views/ledger_view.dart';
import '../../checkout/controllers/address_controller.dart';
import '../../checkout/views/location_picker_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/error_handler.dart';

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
                                authController.pickProfileImage();
                              },
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: const Color(0xFFFFD54F),
                                      backgroundImage: _getProfileImageProvider(authController.profileImagePath.value),
                                      child: _getProfileImageProvider(authController.profileImagePath.value) == null 
                                          ? Text(
                                              authController.userName.value.isNotEmpty 
                                                ? authController.userName.value.substring(0, 1).toUpperCase() 
                                                : 'U',
                                              style: const TextStyle(
                                                color: Color(0xFF25258F),
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
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
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (authController.businessName.value.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        authController.businessName.value,
                                        style: const TextStyle(color: Color(0xFF25258F), fontSize: 13, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    authController.userEmail.value,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (authController.userPhone.value.trim().isNotEmpty) ...[
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
            Obx(() {
              final ordersController = Get.find<OrdersController>();
              if (ordersController.orders.isEmpty) return const SizedBox.shrink();
              
              final lastOrder = ordersController.orders.first;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        ordersController.reorder(lastOrder);
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

                              child: Column(
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
                              ),
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
                ],
              );
            }),


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
                _buildMenuItem(Icons.notifications_outlined, 'Notifications', 'App alert settings', onTap: () {
                  final notifCtrl = Get.put(AppAlertsController());
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
                          Obx(() => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
                            subtitle: Text(notifCtrl.isEnabled.value ? 'Alerts are currently ON' : 'Alerts are currently OFF', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            value: notifCtrl.isEnabled.value,
                            activeColor: const Color(0xFF25258F),
                            onChanged: (val) {
                              notifCtrl.toggle(val);
                            },
                          )),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Close', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ),
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
                      onConfirm: () async {
                        if (Get.isDialogOpen ?? false) {
                          Get.back();
                        }
                        if (!Get.isRegistered<AuthController>()) {
                          Get.put(AuthController());
                        }
                        final authController = Get.find<AuthController>();
                        await authController.logout();
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
    final addressController = Get.isRegistered<AddressController>()
        ? Get.find<AddressController>()
        : Get.put(AddressController());
    addressController.loadAddressesForCurrentUser();

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
            const SizedBox(height: 16),
            Obx(() {
              if (addressController.savedAddresses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No saved addresses yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ),
                );
              }
              return Column(
                children: List.generate(addressController.savedAddresses.length, (index) {
                  final addr = addressController.savedAddresses[index];
                  final isDefault = index == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAddressCard(
                      label: addr['label'] ?? 'Restaurant',
                      address: addr['address'] ?? '',
                      isDefault: isDefault,
                      onSetDefault: () {
                        addressController.setDefaultAddress(index);
                      },
                      onDelete: () {
                        Get.defaultDialog(
                          title: 'Delete Address',
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25258F)),
                          middleText: 'Are you sure you want to delete "${addr['label'] ?? 'Address'}"?',
                          textConfirm: 'Delete',
                          textCancel: 'Cancel',
                          confirmTextColor: Colors.white,
                          buttonColor: Colors.red,
                          onConfirm: () {
                            Get.back();
                            addressController.deleteAddress(index);
                            AppErrorHandler.showSuccess('Deleted', 'Address removed successfully.');
                          },
                        );
                      },
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Add New Address',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showAddAddressDialog(addressController);
                    },
                    icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF25258F)),
                    label: const Text('Type Address', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF25258F), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.back();
                      final result = await Get.to(() => const LocationPickerView());
                      if (result != null && result['address'] != null) {
                        final String addr = result['address'] as String;
                        final String label = (result['label'] as String?) ?? 'New Location';
                        final lat = (result['lat'] as num?)?.toDouble();
                        final lng = (result['lng'] as num?)?.toDouble();
                        addressController.addAddress(label, addr, lat: lat, lng: lng);
                        _showSavedAddresses();
                        AppErrorHandler.showSuccess('Address Added', addr);
                      }
                    },
                    icon: const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    label: const Text('Pick on Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25258F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddAddressDialog(AddressController addressController) {
    final labelCtrl = TextEditingController(text: 'Restaurant');
    final addressCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Address Label (e.g. Branch 2)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Full Address'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25258F), foregroundColor: Colors.white),
            onPressed: () {
              if (addressCtrl.text.trim().isNotEmpty) {
                addressController.addAddress(
                  labelCtrl.text.trim().isEmpty ? 'Restaurant' : labelCtrl.text.trim(),
                  addressCtrl.text.trim(),
                );
                Get.back();
                _showSavedAddresses();
              }
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required String label,
    required String address,
    required bool isDefault,
    required VoidCallback onSetDefault,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefault ? const Color(0xFFF0F0FF) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDefault ? const Color(0xFF25258F) : Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.location_on, color: isDefault ? const Color(0xFF25258F) : Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    if (isDefault) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25258F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Default Address', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      _SetAsDefaultButton(
                        key: ValueKey(address),
                        onPressed: onSetDefault,
                      ),
                    ],
                    if (onDelete != null) ...[
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Address options',
                        onSelected: (value) {
                          if (value == 'remove') {
                            onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Remove Address',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
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

  ImageProvider? _getProfileImageProvider(String path) {
    if (path.isEmpty) return null;
    try {
      if (path.startsWith('data:image')) {
        final clean = path.split(',').last;
        return MemoryImage(base64Decode(clean));
      } else if (path.startsWith('http')) {
        return NetworkImage(path);
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return FileImage(file);
        }
      }
    } catch (e) {
      debugPrint('Error parsing profile image provider: $e');
    }
    return null;
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
            _buildContactRow(Icons.phone, 'Call / WhatsApp', '0321-1655556 • 0321-0655555', onTap: () => _launchUrl('tel:+923211655556')),
            const SizedBox(height: 12),
            _buildContactRow(Icons.location_on, 'Location', '12 G Gulberg Center, Opposite Hafeez Center, Gulberg III, Lahore', onTap: () => _launchUrl('https://maps.google.com/?q=12+G+Gulberg+Center+Lahore')),
            const SizedBox(height: 32),

            // Social Links
            const Text('Follow Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialIcon('assets/images/whatsapp_new.png', 'WhatsApp', const Color(0xFF25D366), () => _launchUrl('https://wa.me/923211655556')),
                _buildSocialIcon('assets/images/facebook.jpg', 'Facebook', const Color(0xFF1877F2), () => _launchUrl('https://www.facebook.com/restomart.lhr')),
                _buildSocialIcon('assets/images/instagram.jpg', 'Instagram', const Color(0xFFE4405F), () => _launchUrl('https://www.instagram.com/restomart.pk')),
                _buildSocialIcon('assets/images/tiktok.png', 'TikTok', Colors.black87, () => _launchUrl('https://www.tiktok.com/@restomart')),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open the link.', snackPosition: SnackPosition.BOTTOM);
    }
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

  Widget _buildContactRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
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
                Text(value, style: TextStyle(fontSize: 13, color: onTap != null ? const Color(0xFF25258F) : Colors.grey.shade600, decoration: onTap != null ? TextDecoration.underline : TextDecoration.none)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(String imagePath, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: imagePath.startsWith('http')
                ? Image.network(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_,__,___) => Icon(Icons.link, color: color, size: 52),
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_,__,___) => Icon(Icons.link, color: color, size: 52),
                  ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
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
                  const Text('Call or WhatsApp', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('03211655556 – 03210655555', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri launchUri = Uri(scheme: 'tel', path: '03211655556');
                            try {
                              await launchUrl(launchUri);
                            } catch (e) {
                              Get.snackbar('Error', 'Could not open dialer.', snackPosition: SnackPosition.BOTTOM, colorText: Colors.white, backgroundColor: Colors.red);
                            }
                          },
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call Us'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD54F),
                            foregroundColor: const Color(0xFF25258F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final Uri whatsappUrl = Uri.parse("https://wa.me/923211655556");
                            try {
                              await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              Get.snackbar('Error', 'WhatsApp could not be opened.', snackPosition: SnackPosition.BOTTOM, colorText: Colors.white, backgroundColor: Colors.red);
                            }
                          },
                          icon: Image.asset(
                            'assets/images/whatsapp_new.png',
                            width: 24,
                            height: 24,
                          ),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
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

class AppAlertsController extends GetxController {
  final isEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('notifications_enabled')) {
      isEnabled.value = prefs.getBool('notifications_enabled') ?? true;
    } else {
      // Check current permission state if no preference was explicitly saved yet
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      isEnabled.value = hasPermission;
      await prefs.setBool('notifications_enabled', hasPermission);
    }
  }

  Future<void> toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
        isEnabled.value = true;
        await prefs.setBool('notifications_enabled', true);
        // Optionally fetch token to re-register on server
        await FirebaseMessaging.instance.getToken();
        Get.snackbar('Notifications Enabled', 'You will now receive alerts.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade50, colorText: Colors.green.shade800);
      } else {
        isEnabled.value = false;
        await prefs.setBool('notifications_enabled', false);
        Get.snackbar('Permission Denied', 'Please enable notifications in your device settings.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade50, colorText: Colors.red.shade800);
      }
    } else {
      isEnabled.value = false;
      await prefs.setBool('notifications_enabled', false);
      // Suppress and unsubscribe
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        // Ignore deletion errors if offline
      }
      Get.snackbar('Notifications Disabled', 'You will no longer receive alerts.', snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _SetAsDefaultButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _SetAsDefaultButton({super.key, required this.onPressed});

  @override
  State<_SetAsDefaultButton> createState() => _SetAsDefaultButtonState();
}

class _SetAsDefaultButtonState extends State<_SetAsDefaultButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    HapticFeedback.lightImpact();
    await _animController.forward();
    await _animController.reverse();

    widget.onPressed();

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: const Color(0xFF25258F).withValues(alpha: 0.15),
          highlightColor: const Color(0xFF25258F).withValues(alpha: 0.08),
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isProcessing ? const Color(0xFF25258F).withValues(alpha: 0.1) : Colors.transparent,
              border: Border.all(color: const Color(0xFF25258F), width: 1.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF25258F)),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF25258F)),
                      SizedBox(width: 4),
                      Text(
                        'Set as Default',
                        style: TextStyle(
                          color: Color(0xFF25258F),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}


