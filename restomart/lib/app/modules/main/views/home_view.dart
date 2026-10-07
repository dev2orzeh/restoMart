import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'all_products_view.dart';
import 'product_details_view.dart';
import 'promotions_view.dart';
import 'recently_viewed_view.dart';
import '../../checkout/controllers/address_controller.dart';
import '../../cart/controllers/cart_controller.dart';

import '../controllers/home_controller.dart';
import '../../ledger/views/ledger_view.dart';

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
            // 1. Deliver to ABC Cafe
            Builder(
              builder: (context) {
                final addressController = Get.isRegistered<AddressController>() 
                    ? Get.find<AddressController>() 
                    : Get.put(AddressController());
                return Obx(() {
                  final addr = addressController.selectedAddress?['address'] ?? 'No Address Added';
              
              return GestureDetector(
                onTap: () {
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
                          const Text('Select Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
                          const SizedBox(height: 16),
                          Obx(() => Column(
                            children: List.generate(addressController.savedAddresses.length, (index) {
                              final savedAddr = addressController.savedAddresses[index];
                              final isSelected = addressController.selectedAddressIndex.value == index;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.location_on, color: isSelected ? const Color(0xFF25258F) : Colors.grey),
                                title: Text(savedAddr['label'] ?? '', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                subtitle: Text(savedAddr['address'] ?? ''),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF25D366)) : null,
                                onTap: () {
                                  addressController.selectAddress(index);
                                  Get.back();
                                },
                              );
                            }),
                          )),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.back(); // close current sheet
                                _showAddAddressDialog(addressController);
                              },
                              icon: const Icon(Icons.add, color: Color(0xFF25258F)),
                              label: const Text('Add New Address', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFF25258F)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    isScrollControlled: true,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF25258F), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          addr,
                          style: const TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF25258F), size: 18),
                    ],
                  ),
                ),
              );
            });
            },),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => const AllProductsView(autoFocusSearch: true));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Text(
                        'Search products, brands & more',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Categories Row (Live)
            Obx(() {
              if (controller.isLoading.value && controller.categories.isEmpty) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCategoryShimmer(),
                    )),
                  ),
                );
              }
              if (controller.categories.isEmpty) return const SizedBox.shrink();

              final bgColors = [
                const Color(0xFFFFF7E6),
                const Color(0xFFFDE8E8),
                const Color(0xFFE6F7FF),
                const Color(0xFFF4F7FF)
              ];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    controller.categories.length > 8 ? 8 : controller.categories.length, 
                    (index) {
                    final cat = controller.categories[index];
                    final String name = cat['name'] ?? 'Unknown';
                    
                    String image = '';
                    if (cat['image'] != null && cat['image']['src'] != null) {
                      image = cat['image']['src'];
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildCategoryItem(name, image, bgColors[index % bgColors.length]),
                    );
                  }),
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
              if (controller.isLoading.value || controller.salePicks.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Deals for businesses'),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: controller.salePicks.map((product) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildDealProductCard(product),
                      )).toList(),
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
                onTap: () => Get.to(() => const AllProductsView(initialCategory: 'Cheese')),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/Cheese.jpeg', width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 7. Products: Mozzarella, Cheddar
            _buildHorizontalProductList('Cheese essentials', controller.cheeseEssentials),
            const SizedBox(height: 24),

            // 8. Promo Banner: Beverages
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(() => const AllProductsView(initialCategory: 'Beverage')),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/beverages.jpeg', width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 8a Products: Beverages
            _buildHorizontalProductList('Beverages', controller.beveragesList),
            const SizedBox(height: 24),

            // 8b. Section: Sale picks
            _buildSectionHeader('Sale picks', icon: Icons.bolt, iconColor: const Color(0xFFFFC400), badge: 'On sale'),
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
                  child: Image.asset('assets/images/orderAgain.jpeg', width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 11. Section: Recently viewed
            _buildSectionHeader('Recently viewed', badge: 'Preview', badgeColor: const Color(0xFFE6E6FF), badgeTextColor: const Color(0xFF25258F)),
            const SizedBox(height: 16),

            // 12. Products: Recently viewed
            Obx(() {
              if (controller.isLoading.value && controller.recentlyViewed.isEmpty) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(width: 140, child: _buildProductShimmer()),
                    )),
                  ),
                );
              }
              if (controller.recentlyViewed.isEmpty) return const SizedBox.shrink();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: controller.recentlyViewed.map((product) => Padding(
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
                      )
                    ),
                  )).toList(),
                ),
              );
            }),
            const SizedBox(height: 24),

            // 13. Promo Banner: Packaging
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(() => const AllProductsView(initialCategory: 'Packaging')),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/packaging.jpeg', width: double.infinity, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 16. Products: Packaging
            _buildHorizontalProductList('Packaging essentials', controller.packagingEssentials),
            const SizedBox(height: 24),
            
            // 17. Section: Picked for your kitchen
            _buildSectionHeader('Picked for your kitchen'),
            const SizedBox(height: 16),

            // 18. Products: Horizontal Cards
            Obx(() {
              if (controller.isLoading.value && controller.pickedForKitchen.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildHorizontalProductShimmer(),
                      const SizedBox(height: 16),
                      _buildHorizontalProductShimmer(),
                    ],
                  ),
                );
              }
              if (controller.pickedForKitchen.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: controller.pickedForKitchen.map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHorizontalProductCard(
                      product.id.toString(),
                      product.name, 
                      '1 item', 
                      product.price, 
                      product.image
                    )
                  )).toList(),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Section: Sauces & Condiments
            _buildHorizontalProductList('Sauces & condiments', controller.saucesList),
            const SizedBox(height: 24),

            // Section: Cleaning supplies
            _buildHorizontalProductList('Cleaning supplies', controller.cleaningList),
            const SizedBox(height: 24),

            // Section: Canned goods
            _buildHorizontalProductList('Canned goods', controller.cannedList),
            const SizedBox(height: 24),
            
            // Promo Banner: Business Ledger
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Get.to(() => const LedgerView()),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/Business ledger banner with invoice illustration.png', width: double.infinity, fit: BoxFit.cover),
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
                  _buildInfoCard(Icons.sell_outlined, 'Bulk pricing', 'Better rates\nfor your business'),
                  _buildInfoCard(Icons.local_shipping_outlined, 'Reliable delivery', 'On time,\nevery time'),
                  _buildInfoCard(Icons.support_agent_rounded, 'Business support', 'Here to help\nyou grow'),
                ],
              ),
            ),

            const SizedBox(height: 120), // padding for floating cart bar
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog(AddressController addressController) {
    final TextEditingController labelController = TextEditingController();
    final TextEditingController addressControllerInput = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Add Address', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Home, Office)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressControllerInput,
              decoration: const InputDecoration(
                labelText: 'House/Apartment Number & Street',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Location picking will be added later.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (addressControllerInput.text.trim().isNotEmpty) {
                String label = labelController.text.trim();
                if (label.isEmpty) label = 'Address';
                addressController.addAddress(label, addressControllerInput.text.trim());
                Get.back();
                Get.snackbar(
                  'Address Added', 
                  'Your new address has been saved.',
                  backgroundColor: Colors.green.shade50,
                  colorText: Colors.green.shade800,
                  snackPosition: SnackPosition.TOP,
                );
              } else {
                Get.snackbar('Required', 'Please enter an address.', backgroundColor: Colors.red.shade50, colorText: Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25258F), foregroundColor: Colors.white),
            child: const Text('Save Address'),
          ),
        ],
      )
    );
  }

  Widget _buildCategoryItem(String name, String image, Color bgColor) {
    return GestureDetector(
      onTap: () {
        // Open the category
        Get.to(() => AllProductsView(initialCategory: name));
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: image.isEmpty 
                ? const Icon(Icons.image_not_supported, color: Colors.grey)
                : image.startsWith('http') 
                  ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, memCacheWidth: 140, placeholder: (c,u) => const SizedBox(), errorWidget: (c,u,e) => const Icon(Icons.image_not_supported, color: Colors.grey))
                  : Image.asset(
                      image, 
                      fit: BoxFit.contain,
                    ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF25258F), height: 1.1)),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon, Color? iconColor, String? badge, Color? badgeColor, Color? badgeTextColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 6),
          ],
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF25258F))),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (badge == 'On sale') const Icon(Icons.access_time_filled, size: 12, color: Color(0xFFE53935)),
                  if (badge == 'On sale') const SizedBox(width: 4),
                  Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor ?? const Color(0xFFE53935))),
                ],
              ),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (title == 'Recently viewed') {
                Get.to(() => const RecentlyViewedView());
              } else {
                Get.to(() => AllProductsView(initialCategory: title));
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View all', style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Color(0xFF25258F), size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(String id, String name, String quantity, int price, String image, bool isOnSale, {int? originalPrice, bool fullAddToCart = false}) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailsView(
              id: id,
              imagePath: image,
              name: name,
              salePrice: price.toDouble(),
              originalPrice: originalPrice?.toDouble() ?? price.toDouble(),
            ));
      },
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: image.isEmpty 
                  ? const Icon(Icons.image_not_supported, color: Colors.grey)
                  : image.startsWith('http') 
                    ? CachedNetworkImage(imageUrl: image, fit: BoxFit.contain, memCacheWidth: 280, placeholder: (c,u) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (c,u,e) => const Icon(Icons.image_not_supported, color: Colors.grey))
                    : Image.asset(image, fit: BoxFit.contain),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.favorite_border, color: Colors.grey.shade400, size: 20),
              ),
              if (isOnSale)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4)),
                    child: const Text('On sale', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF25258F))),
                const SizedBox(height: 4),
                Text(quantity, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rs. $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF25258F))),
                    if (originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text('Rs. $originalPrice', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, decoration: TextDecoration.lineThrough)),
                    ]
                  ],
                ),
                if (fullAddToCart) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                      label: const Text('Add to cart', style: TextStyle(color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25258F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                ] else ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        if (Get.isRegistered<CartController>()) {
                          Get.find<CartController>().addToCart(
                            id,
                            image,
                            name,
                            price.toDouble(),
                            1
                          );
                          Get.snackbar(
                            'Added to Cart',
                            '$name added to your cart',
                            snackPosition: SnackPosition.TOP,
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green.shade50,
                            colorText: Colors.green.shade800,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF25258F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildHorizontalProductCard(String id, String name, String quantity, int price, String image) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailsView(
              id: id,
              imagePath: image,
              name: name,
              salePrice: price.toDouble(),
              originalPrice: price.toDouble(),
            ));
      },
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(12),
            child: image.isEmpty 
              ? const Icon(Icons.image_not_supported, color: Colors.grey)
              : image.startsWith('http') 
                ? CachedNetworkImage(imageUrl: image, fit: BoxFit.contain, memCacheWidth: 200, placeholder: (c,u) => const SizedBox(), errorWidget: (c,u,e) => const Icon(Icons.image_not_supported, color: Colors.grey))
                : Image.asset(image, fit: BoxFit.contain),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF25258F)))),
                      Icon(Icons.favorite_border, color: Colors.grey.shade400, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(quantity, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rs. $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF25258F))),
                      GestureDetector(
                        onTap: () {
                          if (Get.isRegistered<CartController>()) {
                            Get.find<CartController>().addToCart(
                              id,
                              image,
                              name,
                              price.toDouble(),
                              1
                            );
                            Get.snackbar(
                              'Added to Cart',
                              '$name added to your cart',
                              snackPosition: SnackPosition.TOP,
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green.shade50,
                              colorText: Colors.green.shade800,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25258F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildHorizontalProductList(String title, RxList<WooCommerceProduct> list, {IconData? icon, Color? iconColor, String? badge, Color? badgeColor, Color? badgeTextColor}) {
    return Obx(() {
      if (!controller.isLoading.value && list.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, icon: icon, iconColor: iconColor, badge: badge, badgeColor: badgeColor, badgeTextColor: badgeTextColor),
          const SizedBox(height: 16),
          if (controller.isLoading.value && list.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(3, (index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(width: 140, child: _buildProductShimmer()),
                )),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: list.map((product) => Padding(
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
                    )
                  ),
                )).toList(),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildDealProductCard(WooCommerceProduct product) {
    int discountPercent = 0;
    if (product.isOnSale && product.originalPrice != null && product.originalPrice! > 0) {
      discountPercent = (((product.originalPrice! - product.price) / product.originalPrice!) * 100).round();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (Get.isRegistered<CartController>()) {
          Get.to(() => ProductDetailsView(
            id: product.id.toString(),
            name: product.name,
            imagePath: product.image,
            salePrice: product.price.toDouble(),
            originalPrice: (product.originalPrice ?? product.price).toDouble(),
          ));
        }
      },
      child: Container(
        width: 320,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            // Left Side - Image and Tag
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 140,
                  padding: const EdgeInsets.all(12),
                  child: product.image.isEmpty 
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : (product.image.startsWith('http') 
                        ? CachedNetworkImage(imageUrl: product.image, fit: BoxFit.contain, memCacheWidth: 240, placeholder: (c,u) => const SizedBox(), errorWidget: (c,u,e) => const Icon(Icons.image_not_supported, color: Colors.grey))
                        : Image.asset(product.image, fit: BoxFit.contain)),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107), // Yellow tag
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Right Side - Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1B1B3A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'PKR ${product.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B1B3A),
                      ),
                    ),
                    if (product.originalPrice != null && product.originalPrice! > product.price)
                      Text(
                        'PKR ${product.originalPrice}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Add Button
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 12),
                child: GestureDetector(
                  onTap: () {
                    if (Get.isRegistered<CartController>()) {
                      Get.find<CartController>().addToCart(
                        product.id.toString(),
                        product.image,
                        product.name,
                        product.price.toDouble(),
                        1
                      );
                      Get.snackbar(
                        'Added to Cart',
                        '${product.name} added to your cart',
                        snackPosition: SnackPosition.TOP,
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green.shade50,
                        colorText: Colors.green.shade800,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B4A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          child: Container(width: 70, height: 70, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ),
        const SizedBox(height: 8),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(width: 50, height: 10, color: Colors.white),
        )
      ],
    );
  }

  Widget _buildProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 220,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHorizontalProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF25258F))),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AutoSwipingBanner extends StatefulWidget {
  const _AutoSwipingBanner({Key? key}) : super(key: key);

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
            child: Image.asset('assets/images/heroCard.png', width: double.infinity, fit: BoxFit.cover),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const PromotionsView()),
            child: Image.asset('assets/images/minimalist_yellow_sale_banner.png', width: double.infinity, fit: BoxFit.cover),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const AllProductsView()),
            child: Image.asset('assets/images/restomart_grocery_category_shopping_banner_1.png', width: double.infinity, fit: BoxFit.cover),
          ),
          GestureDetector(
            onTap: () => Get.to(() => const LedgerView()),
            child: Image.asset('assets/images/business_ledger_at_a_glance_2.png', width: double.infinity, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
