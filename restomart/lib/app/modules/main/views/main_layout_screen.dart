import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/restomart_logo.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../controllers/main_controller.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../cart/views/cart_view.dart';
import '../../account/views/account_view.dart';
import 'home_view.dart';
import 'categories_view.dart';
import 'promotions_view.dart';
import 'notifications_view.dart';
import '../controllers/notifications_controller.dart';

class MainLayoutScreen extends GetView<MainController> {
  MainLayoutScreen({super.key});

  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (controller.currentIndex.value != 2) {
          // If not on Home tab, return to Home tab
          controller.changeTab(2);
        } else {
          // If on Home tab, show exit confirmation dialog
          final shouldExit = await Get.dialog<bool>(
            ConfirmationDialog(
              title: 'Are you sure you want to exit?',
              cancelText: 'Go back',
              confirmText: 'Exit App',
              onConfirm: () => Get.back(result: true),
            ),
          );
          
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/homePageLogo.webp',
          height: 28,
          fit: BoxFit.contain,
        ),
        actions: [
          Obx(() {
            final cartItemsCount = cartController.totalItems;
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Color(0xFF25258F)),
                  if (cartItemsCount > 0)
                    Positioned(
                      right: -3,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC400),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        child: Text(
                          '$cartItemsCount',
                          style: const TextStyle(
                            color: Color(0xFF1B1B3A),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Get.to(() => CartView());
              },
            );
          }),
          Builder(
            builder: (context) {
              final notifController = Get.isRegistered<NotificationsController>() 
                  ? Get.find<NotificationsController>() 
                  : Get.put(NotificationsController());
              return Obx(() {
                final unreadCount = notifController.unreadCount;
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Color(0xFF25258F)),
                      if (unreadCount > 0)
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC400),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        )
                    ],
                  ),
                  onPressed: () {
                    Get.to(() => const NotificationsView());
                  },
                );
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            return IndexedStack(
              index: controller.currentIndex.value,
              children: [
                const CategoriesView(),
                const PromotionsView(),
                HomeView(),
                const NotificationsView(),
                const AccountView(),
              ],
            );
          }),
          Obx(() {
            if (cartController.totalItems == 0) return const SizedBox.shrink();
            
            return Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Get.to(() => CartView()),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC400),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Color(0xFF25258F), size: 26),
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25258F),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFC400), width: 1.5),
                              ),
                              child: Text(
                                '${cartController.totalItems}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'View cart',
                        style: TextStyle(
                          color: Color(0xFF25258F),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'PKR ${cartController.totalPrice.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFF25258F),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Color(0xFF25258F), size: 16),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.changeTab(2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: RestoMartLogo(size: 40, showText: false),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.navBarBackground,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.category_outlined, activeIcon: Icons.category_rounded, label: 'Categories', index: 0),
              _buildNavItem(icon: Icons.card_giftcard_outlined, activeIcon: Icons.card_giftcard_rounded, label: 'Promotions', index: 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(icon: Icons.notifications_none_rounded, activeIcon: Icons.notifications_rounded, label: 'Notifications', index: 3),
              _buildNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Account', index: 4),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required IconData activeIcon, required String label, required int index}) {
    return Obx(() {
      final isSelected = controller.currentIndex.value == index;
      final color = isSelected ? AppColors.primary : const Color(0xFF8B92A5);

      return InkWell(
        onTap: () => controller.changeTab(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon, 
                  color: color, 
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
