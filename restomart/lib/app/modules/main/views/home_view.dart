import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'all_products_view.dart';
import 'product_details_view.dart';
import 'promotions_view.dart';
import 'recently_viewed_view.dart';
import 'search_view.dart';
import '../../favorites/views/favorites_view.dart';
import '../../checkout/controllers/address_controller.dart';
import '../../checkout/views/location_picker_view.dart';
import '../../cart/controllers/cart_controller.dart';

import '../controllers/home_controller.dart';
import '../../ledger/views/ledger_view.dart';
import '../../../core/utils/error_handler.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key});

  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Section (Address & Search with Translucent Dark Golden Yellow Theme) ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFE8961C).withValues(alpha: 0.18),
                    const Color(0xFFE8961C).withValues(alpha: 0.07),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address Row: Corner Placement
                  Builder(
                    builder: (context) {
                      final addressController =
                          Get.isRegistered<AddressController>()
                          ? Get.find<AddressController>()
                          : Get.put(AddressController());
                      return Obx(() {
                        final selected = addressController.selectedAddress;
                        final fullAddr =
                            selected?['address'] ?? 'Select Delivery Address';
                        final label =
                            (selected?['label'] != null &&
                                selected!['label']!.isNotEmpty)
                            ? selected['label']!
                            : (fullAddr.contains(',')
                                  ? fullAddr.split(',').first.trim()
                                  : fullAddr);
                        final city =
                            selected?['city'] ??
                            (fullAddr.contains(',')
                                ? fullAddr.split(',').last.trim()
                                : 'Lahore');

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showAddressSelectionSheet(
                                  context,
                                  addressController,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFF25258F),
                                      size: 26,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  label,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1B1B3A),
                                                    fontSize: 16.5,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.3,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: Color(0xFF25258F),
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            city,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Corner Action: Saved Items / Favorites
                            GestureDetector(
                              onTap: () => Get.to(() => const FavoritesView()),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE8961C,
                                      ).withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: Color(0xFF1B1B3A),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        );
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── Search Bar: Pleasing, Attractive Rounded Pill ──
                  GestureDetector(
                    onTap: () {
                      Get.to(() => const SearchView());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFE8961C).withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE8961C,
                            ).withValues(alpha: 0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF25258F,
                              ).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF25258F),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Search any product',
                              style: TextStyle(
                                color: Color(0xFF5A6474),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Categories Row (Live)
            Obx(() {
              if (controller.isLoading.value && controller.categories.isEmpty) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildCategoryShimmer(),
                      ),
                    ),
                  ),
                );
              }
              if (controller.categories.isEmpty) return const SizedBox.shrink();

              final bgColors = [
                const Color(0xFFFFF7E6),
                const Color(0xFFFDE8E8),
                const Color(0xFFE6F7FF),
                const Color(0xFFF4F7FF),
              ];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    controller.categories.length > 8
                        ? 8
                        : controller.categories.length,
                    (index) {
                      final cat = controller.categories[index];
                      final String name = cat['name'] ?? 'Unknown';

                      String image = '';
                      if (cat['image'] != null && cat['image']['src'] != null) {
                        image = cat['image']['src'];
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildCategoryItem(
                          name,
                          image,
                          bgColors[index % bgColors.length],
                          categoryId: cat['id']?.toString(),
                        ),
                      );
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // 4. Promo Banner 1: Stock up. Save more. (Auto Swiping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const _AutoSwipingBanner(),
              ),
            ),
            const SizedBox(height: 24),

            // Deals for businesses
            Obx(() {
              if (controller.isLoading.value && controller.salePicks.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Deals for businesses'),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: List.generate(
                          2,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 325,
                              child: _buildHorizontalProductShimmer(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }
              if (controller.salePicks.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Deals for businesses',
                    icon: Icons.local_offer_rounded,
                    iconColor: const Color(0xFFFF9800),
                    badge: 'Special Combos',
                    badgeColor: const Color(0xFFFFF3E0),
                    badgeTextColor: const Color(0xFFE65100),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: controller.salePicks
                          .map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _buildDealProductCard(product),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),

            // 6. Cheese Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Cheese',
                    pageTitle: 'Cheese Essentials',
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/Cheese.jpeg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 7. Products: Mozzarella, Cheddar
            _buildHorizontalProductList(
              'Cheese essentials',
              controller.cheeseEssentials,
              subtitle: 'Mozzarella, cheddar & sliced cheese blocks for kitchens',
              icon: Icons.lunch_dining_rounded,
              iconColor: const Color(0xFFF57C00),
            ),
            const SizedBox(height: 24),

            // 8. Promo Banner: Beverages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Beverages',
                    pageTitle: 'Beverages & Soft Drinks',
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/beverages.jpeg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 8a Products: Beverages
            _buildHorizontalProductList(
              'Beverages & drinks',
              controller.beveragesList,
              subtitle: 'Soft drinks, juices & coffee sachets for your menu',
              icon: Icons.local_drink_rounded,
              iconColor: const Color(0xFF0288D1),
            ),
            const SizedBox(height: 24),

            // 8b. Section: Sale picks
            _buildSectionHeader(
              'Sale picks',
              icon: Icons.bolt,
              iconColor: const Color(0xFFFFC400),
              badge: 'On sale',
            ),
            const SizedBox(height: 16),

            // 9. Products: Sale picks
            Obx(() {
              if (controller.isLoading.value && controller.salePicks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(child: _buildProductShimmer()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildProductShimmer()),
                    ],
                  ),
                );
              }
              if (controller.salePicks.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (controller.salePicks.isNotEmpty)
                      Expanded(
                        child: _buildProductCard(
                          controller.salePicks[0].id.toString(),
                          controller.salePicks[0].name,
                          '1 item',
                          controller.salePicks[0].price,
                          controller.salePicks[0].image,
                          controller.salePicks[0].isOnSale,
                          originalPrice: controller.salePicks[0].originalPrice,
                          fullAddToCart: true,
                        ),
                      ),
                    const SizedBox(width: 16),
                    if (controller.salePicks.length > 1)
                      Expanded(
                        child: _buildProductCard(
                          controller.salePicks[1].id.toString(),
                          controller.salePicks[1].name,
                          '1 item',
                          controller.salePicks[1].price,
                          controller.salePicks[1].image,
                          controller.salePicks[1].isOnSale,
                          originalPrice: controller.salePicks[1].originalPrice,
                          fullAddToCart: true,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // 10. Promo Banner: Your usuals
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(() => const RecentlyViewedView()),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/orderAgain.jpeg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 11. Section: Recently viewed
            _buildSectionHeader(
              'Recently viewed',
              badge: 'Preview',
              badgeColor: const Color(0xFFE6E6FF),
              badgeTextColor: const Color(0xFF25258F),
            ),
            const SizedBox(height: 16),

            // 12. Products: Recently viewed
            Obx(() {
              if (controller.isLoading.value &&
                  controller.recentlyViewed.isEmpty) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 140,
                          child: _buildProductShimmer(),
                        ),
                      ),
                    ),
                  ),
                );
              }
              if (controller.recentlyViewed.isEmpty)
                return const SizedBox.shrink();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: controller.recentlyViewed
                      .map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 140,
                            child: _buildProductCard(
                              product.id.toString(),
                              product.name,
                              '1 item',
                              product.price,
                              product.image,
                              product.isOnSale,
                              originalPrice: product.originalPrice,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }),
            const SizedBox(height: 24),

            // 13. Promo Banner: Packaging
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Packaging',
                    pageTitle: 'Packaging Essentials',
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/packaging.jpeg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 16. Products: Packaging
            _buildHorizontalProductList(
              'Packaging essentials',
              controller.packagingEssentials,
              subtitle: 'Thermocol boxes, gloves & takeaway containers',
              icon: Icons.inventory_2_rounded,
              iconColor: const Color(0xFF7B1FA2),
            ),
            const SizedBox(height: 24),


            // Section: Sauces & Condiments
            _buildHorizontalProductList(
              'Sauces & condiments',
              controller.saucesList,
              subtitle: 'Peri-peri sauces, ketchups & commercial restaurant dips',
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFFE65100),
            ),
            const SizedBox(height: 24),

            // Section: Cleaning supplies
            _buildHorizontalProductList(
              'Cleaning supplies',
              controller.cleaningList,
              subtitle: 'Commercial soaps, air fresheners & hygiene essentials',
              icon: Icons.cleaning_services_rounded,
              iconColor: const Color(0xFF00897B),
            ),
            const SizedBox(height: 24),

            // Section: Canned goods
            _buildHorizontalProductList(
              'Canned goods',
              controller.cannedList,
              subtitle: 'Sliced jalapenos, beans, sweet corn & pantry staples',
              icon: Icons.kitchen_rounded,
              iconColor: const Color(0xFF5D4037),
            ),
            const SizedBox(height: 24),

            // Promo Banner: Business Ledger
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(() => const LedgerView()),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/Business ledger banner with invoice illustration.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 19. Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoCard(
                    Icons.sell_outlined,
                    'Bulk pricing',
                    'Better rates\nfor your business',
                  ),
                  _buildInfoCard(
                    Icons.local_shipping_outlined,
                    'Reliable delivery',
                    'On time,\nevery time',
                  ),
                  _buildInfoCard(
                    Icons.support_agent_rounded,
                    'Business support',
                    'Here to help\nyou grow',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 20. View All Products CTA Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.to(() => const AllProductsView(pageTitle: 'All Products')),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25258F), Color(0xFF191967)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25258F).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFFFFC400),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View All Products',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Explore complete wholesale catalog',
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF1B1B3A),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 120), // padding for floating cart bar
          ],
        ),
      ),
    );
  }

  void _showAddressSelectionSheet(
    BuildContext context,
    AddressController addressController,
  ) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25258F),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Saved Addresses List
            Obx(() {
              if (addressController.savedAddresses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF25258F), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No saved addresses yet. Choose an option below to add your address.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addressController.savedAddresses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final savedAddr = addressController.savedAddresses[index];
                    final isSelected =
                        addressController.selectedAddressIndex.value == index;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF25258F).withOpacity(0.1)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? const Color(0xFF25258F)
                              : Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        savedAddr['label'] ?? 'Address',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF25258F)
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        savedAddr['address'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF25258F),
                            )
                          : null,
                      onTap: () {
                        addressController.selectAddress(index);
                        Get.back();
                      },
                    );
                  },
                ),
              );
            }),

            const SizedBox(height: 16),
            const Text(
              'Add New Delivery Address',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),

            // Two distinct options: Type Address vs Pick on Map
            Row(
              children: [
                // Option 1: Type Address
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showAddAddressDialog(addressController);
                    },
                    icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF25258F)),
                    label: const Text(
                      'Type Address',
                      style: TextStyle(
                        color: Color(0xFF25258F),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF25258F), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Option 2: Pick on Map
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.back();
                      final result = await Get.to(() => const LocationPickerView());
                      if (result != null && result['address'] != null) {
                        final String addr = result['address'] as String;
                        final String label = (result['label'] as String?) ?? 'My Location';
                        final lat = (result['lat'] as num?)?.toDouble();
                        final lng = (result['lng'] as num?)?.toDouble();
                        addressController.addAddress(label, addr, lat: lat, lng: lng);
                        AppErrorHandler.showSuccess('Location Selected', addr);
                      }
                    },
                    icon: const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                    label: const Text(
                      'Pick on Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25258F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAddAddressDialog(AddressController addressController) {
    final TextEditingController labelController = TextEditingController(text: 'Home');
    final TextEditingController addressControllerInput = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Type Delivery Address',
          style: TextStyle(
            color: Color(0xFF25258F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'Label (e.g. Home, Office, Restaurant)',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: addressControllerInput,
              decoration: InputDecoration(
                labelText: 'House / Shop #, Street, Area, City',
                hintText: 'e.g. House #14, Street 2, Gulberg III, Lahore',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25258F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (addressControllerInput.text.trim().isNotEmpty) {
                String label = labelController.text.trim();
                if (label.isEmpty) label = 'Address';
                addressController.addAddress(
                  label,
                  addressControllerInput.text.trim(),
                );
                Get.back();
                AppErrorHandler.showSuccess(
                  'Address Saved',
                  'Your delivery address has been saved and selected.',
                );
              } else {
                AppErrorHandler.showWarning(
                  'Required',
                  'Please enter your address details.',
                );
              }
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String name,
    String image,
    Color bgColor, {
    String? categoryId,
  }) {
    return GestureDetector(
      onTap: () {
        // Open the category with both name and categoryId
        Get.to(
          () => AllProductsView(
            initialCategory: name,
            initialCategoryId: categoryId,
            pageTitle: name,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: image.isEmpty
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : image.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    memCacheWidth: 140,
                    placeholder: (c, u) => const SizedBox(),
                    errorWidget: (c, u, e) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  )
                : Image.asset(image, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF25258F),
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25258F),
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFFFFEAEA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (badge == 'On sale')
                              const Icon(
                                Icons.access_time_filled,
                                size: 12,
                                color: Color(0xFFE53935),
                              ),
                            if (badge == 'On sale') const SizedBox(width: 3),
                            Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeTextColor ?? const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final lower = title.toLowerCase();
              if (lower.contains('recently')) {
                Get.to(() => const RecentlyViewedView());
              } else if (lower.contains('kitchen')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Kitchen Accessories',
                    pageTitle: 'Kitchen Accessories',
                  ),
                );
              } else if (lower.contains('deal') || lower.contains('sale')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Deals & Promotions',
                    pageTitle: 'Sale Picks & Deals',
                    onlyOnSale: true,
                  ),
                );
              } else if (lower.contains('beverage') || lower.contains('drink')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Beverages',
                    pageTitle: 'Beverages & Soft Drinks',
                  ),
                );
              } else if (lower.contains('pack')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Packaging',
                    pageTitle: 'Packaging Essentials',
                  ),
                );
              } else if (lower.contains('clean') || lower.contains('hygiene')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Cleaning',
                    pageTitle: 'Cleaning & Hygiene',
                  ),
                );
              } else if (lower.contains('sauce')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Sauce',
                    pageTitle: 'Sauces & Condiments',
                  ),
                );
              } else if (lower.contains('cheese')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Cheese',
                    pageTitle: 'Cheese Essentials',
                  ),
                );
              } else if (lower.contains('canned')) {
                Get.to(
                  () => const AllProductsView(
                    initialCategory: 'Canned',
                    pageTitle: 'Canned Products',
                  ),
                );
              } else {
                Get.to(
                  () => AllProductsView(initialCategory: title, pageTitle: title),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF25258F).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFF25258F),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF25258F), size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    String id,
    String name,
    String quantity,
    int price,
    String image,
    bool isOnSale, {
    int? originalPrice,
    bool fullAddToCart = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Get.to(
                () => ProductDetailsView(
                  id: id,
                  imagePath: image,
                  name: name,
                  salePrice: price.toDouble(),
                  originalPrice: originalPrice?.toDouble() ?? price.toDouble(),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: image.isEmpty
                      ? const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        )
                      : image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.contain,
                          memCacheWidth: 280,
                          placeholder: (c, u) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (c, u, e) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        )
                      : Image.asset(image, fit: BoxFit.contain),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                if (isOnSale)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'On sale',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => ProductDetailsView(
                        id: id,
                        imagePath: image,
                        name: name,
                        salePrice: price.toDouble(),
                        originalPrice:
                            originalPrice?.toDouble() ?? price.toDouble(),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF25258F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quantity,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs. $price',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF25258F),
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Rs. $originalPrice',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final cartController = Get.isRegistered<CartController>()
                      ? Get.find<CartController>()
                      : Get.put(CartController());

                  final isInCart = cartController.isInCart(name);

                  if (isInCart) {
                    final quantityVal = cartController.getProductQuantity(name);
                    return Container(
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF25258F)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              final item = cartController.cartItems.firstWhere(
                                (i) => i.name == name,
                              );
                              cartController.decreaseQuantity(item);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Icon(
                                Icons.remove,
                                size: 14,
                                color: Color(0xFF25258F),
                              ),
                            ),
                          ),
                          Text(
                            '$quantityVal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF25258F),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final item = cartController.cartItems.firstWhere(
                                (i) => i.name == name,
                              );
                              cartController.increaseQuantity(item);
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Icon(
                                Icons.add,
                                size: 14,
                                color: Color(0xFF25258F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () {
                        cartController.addToCart(
                          id,
                          image,
                          name,
                          price.toDouble(),
                          1,
                          originalPrice: originalPrice?.toDouble(),
                        );
                        Get.snackbar(
                          'Added to Cart',
                          '$name added to your cart',
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.green.shade50,
                          colorText: Colors.green.shade800,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25258F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Add to cart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25258F),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHorizontalProductList(
    String title,
    RxList<WooCommerceProduct> list, {
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Obx(() {
      if (!controller.isLoading.value && list.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title,
            subtitle: subtitle,
            icon: icon,
            iconColor: iconColor,
            badge: badge,
            badgeColor: badgeColor,
            badgeTextColor: badgeTextColor,
          ),
          const SizedBox(height: 14),
          if (controller.isLoading.value && list.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SizedBox(width: 140, child: _buildProductShimmer()),
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: list
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 140,
                          child: _buildProductCard(
                            product.id.toString(),
                            product.name,
                            '1 item',
                            product.price,
                            product.image,
                            product.isOnSale,
                            originalPrice: product.originalPrice,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildDealProductCard(WooCommerceProduct product) {
    int discountPercent = 0;
    if (product.isOnSale &&
        product.originalPrice != null &&
        product.originalPrice! > 0) {
      discountPercent =
          (((product.originalPrice! - product.price) / product.originalPrice!) *
                  100)
              .round();
    }

    return Container(
      width: 325,
      height: 175,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25258F).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8ECF5), width: 1.2),
      ),
      child: Row(
        children: [
          // Left Side - Image, Background & Discount Tag
          GestureDetector(
            onTap: () {
              Get.to(
                () => ProductDetailsView(
                  id: product.id.toString(),
                  name: product.name,
                  imagePath: product.image,
                  salePrice: product.price.toDouble(),
                  originalPrice: (product.originalPrice ?? product.price)
                      .toDouble(),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 125,
                  height: 175,
                  color: const Color(0xFFF7F8FC),
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: product.image.isEmpty
                        ? const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey,
                            size: 36,
                          )
                        : (product.image.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: product.image,
                                  fit: BoxFit.contain,
                                  memCacheWidth: 260,
                                  placeholder: (c, u) => const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (c, u, e) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                    size: 36,
                                  ),
                                )
                              : Image.asset(
                                  product.image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFFF7F8FC),
                                    child: Center(
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        color: const Color(0xFF25258F).withValues(alpha: 0.35),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF6F00,
                            ).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Right Side - Details & Controls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(
                        () => ProductDetailsView(
                          id: product.id.toString(),
                          name: product.name,
                          imagePath: product.image,
                          salePrice: product.price.toDouble(),
                          originalPrice:
                              (product.originalPrice ?? product.price)
                                  .toDouble(),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.category.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF25258F,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF25258F),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: Color(0xFF1B1B3A),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs. ${product.price}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF25258F),
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (product.originalPrice != null &&
                                product.originalPrice! > product.price)
                              Text(
                                'Rs. ${product.originalPrice}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Obx(() {
                        final cartController =
                            Get.isRegistered<CartController>()
                            ? Get.find<CartController>()
                            : Get.put(CartController());

                        final isInCart = cartController.isInCart(product.name);

                        if (isInCart) {
                          final quantityVal = cartController.getProductQuantity(
                            product.name,
                          );
                          return Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF25258F,
                              ).withValues(alpha: 0.06),
                              border: Border.all(
                                color: const Color(0xFF25258F),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    final item = cartController.cartItems
                                        .firstWhere(
                                          (i) => i.name == product.name,
                                        );
                                    cartController.decreaseQuantity(item);
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 7.0,
                                      vertical: 4.0,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 14,
                                      color: Color(0xFF25258F),
                                    ),
                                  ),
                                ),
                                Text(
                                  '$quantityVal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                    color: Color(0xFF25258F),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final item = cartController.cartItems
                                        .firstWhere(
                                          (i) => i.name == product.name,
                                        );
                                    cartController.increaseQuantity(item);
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 7.0,
                                      vertical: 4.0,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Color(0xFF25258F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Material(
                          color: const Color(0xFF25258F),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              cartController.addToCart(
                                product.id.toString(),
                                product.image,
                                product.name,
                                product.price.toDouble(),
                                1,
                                originalPrice: product.originalPrice
                                    ?.toDouble(),
                              );
                              Get.snackbar(
                                'Added to Cart',
                                '${product.name} added to your cart',
                                snackPosition: SnackPosition.TOP,
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF25258F),
                                colorText: Colors.white,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Shimmer Loaders ---
  Widget _buildCategoryShimmer() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(width: 50, height: 10, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildHorizontalProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 175,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String desc) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF25258F), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFF25258F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSwipingBanner extends StatefulWidget {
  const _AutoSwipingBanner();

  @override
  State<_AutoSwipingBanner> createState() => _AutoSwipingBannerState();
}

class _AutoSwipingBannerState extends State<_AutoSwipingBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 3) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.2, // standard banner ratio
      child: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          GestureDetector(
            onTap: () => Get.to(() => const AllProductsView()),
            child: Image.asset(
              'assets/images/heroCard.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const PromotionsView()),
            child: Image.asset(
              'assets/images/minimalist_yellow_sale_banner.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const AllProductsView()),
            child: Image.asset(
              'assets/images/restomart_grocery_category_shopping_banner_1.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const LedgerView()),
            child: Image.asset(
              'assets/images/business_ledger_at_a_glance_2.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
