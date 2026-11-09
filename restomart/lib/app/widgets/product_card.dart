import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../modules/main/views/product_details_view.dart';
import '../modules/cart/controllers/cart_controller.dart';
import '../modules/cart/views/cart_view.dart';
import '../modules/favorites/controllers/favorites_controller.dart';
import '../modules/main/controllers/recently_viewed_controller.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String imagePath;
  final List<String>? imagePaths;
  final String name;
  final double salePrice;
  final double originalPrice;
  final int discountPercent;
  final VoidCallback onAddToCart;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const ProductCard({
    super.key,
    required this.id,
    required this.imagePath,
    this.imagePaths,
    required this.name,
    required this.salePrice,
    required this.originalPrice,
    required this.discountPercent,
    required this.onAddToCart,
    this.width = 150,
    this.margin = const EdgeInsets.only(right: 16),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Track recently viewed
        if (Get.isRegistered<RecentlyViewedController>()) {
          Get.find<RecentlyViewedController>().addProduct(
            RecentlyViewedProduct(
              imagePath: imagePath,
              imagePaths: imagePaths,
              name: name,
              price: salePrice,
              originalPrice: originalPrice,
              discountPercent: discountPercent.toDouble(),
            )
          );
        }

        Get.to(() => ProductDetailsView(
              id: id,
              imagePath: imagePath,
              imagePaths: imagePaths,
              name: name,
              salePrice: salePrice,
              originalPrice: originalPrice,
            ), preventDuplicates: false);
      },
      child: Container(
        width: width,
        margin: margin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Badges
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: imagePath.isEmpty
                      ? Icon(Icons.inventory_2_outlined, color: const Color(0xFF25258F).withValues(alpha: 0.35), size: 36)
                      : imagePath.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.contain,
                            memCacheWidth: 240,
                            placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (context, url, error) => Icon(Icons.inventory_2_outlined, color: const Color(0xFF25258F).withValues(alpha: 0.35), size: 36),
                          )
                        : Image.asset(
                            imagePath, 
                            fit: BoxFit.contain, 
                            errorBuilder: (_,__,___) => Icon(Icons.inventory_2_outlined, color: const Color(0xFF25258F).withValues(alpha: 0.35), size: 36),
                          ),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F), // Dark, prominent red
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12), // matches card corner
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      final favoritesController = Get.isRegistered<FavoritesController>() 
                          ? Get.find<FavoritesController>() 
                          : Get.put(FavoritesController());
                      
                      favoritesController.toggleFavorite(
                        id: id,
                        imagePath: imagePath,
                        name: name,
                        salePrice: salePrice,
                        originalPrice: originalPrice,
                        discountPercent: discountPercent,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Obx(() {
                        final favoritesController = Get.isRegistered<FavoritesController>() 
                            ? Get.find<FavoritesController>() 
                            : Get.put(FavoritesController());
                        
                        final isFav = favoritesController.isFavorite(name);
                        return Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFav ? const Color(0xFFE53E3E) : Colors.grey.shade400,
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

          // Product Name
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),

          // Price and Stock
          Row(
            children: [
              Text(
                'Rs. ${salePrice.toInt()}',
                style: AppTextStyles.priceSale,
              ),
              const SizedBox(width: 8),
              if (originalPrice > salePrice)
                Text(
                  'Rs. ${originalPrice.toInt()}',
                  style: AppTextStyles.priceOriginal,
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'In Stock',
            style: TextStyle(
              color: Color(0xFF10B981), // Green
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Add to Cart Button (pushed to bottom)
          const Spacer(),
          Obx(() {
            final cartController = Get.isRegistered<CartController>() 
                ? Get.find<CartController>() 
                : Get.put(CartController());
                
            final isInCart = cartController.isInCart(name);
            
            if (isInCart) {
              final quantity = cartController.getProductQuantity(name);
              return Container(
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        final item = cartController.cartItems.firstWhere((i) => i.name == name);
                        cartController.decreaseQuantity(item);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.remove, size: 16, color: AppColors.primary),
                      ),
                    ),
                    Text(
                      '$quantity',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () {
                        final item = cartController.cartItems.firstWhere((i) => i.name == name);
                        cartController.increaseQuantity(item);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(Icons.add, size: 16, color: AppColors.primary),
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
                  try {
                    cartController.addToCart(id, imagePath, name, salePrice, 1, originalPrice: originalPrice);
                    Get.snackbar(
                      'Added to Cart',
                      '1 x $name added to your cart.',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: Colors.green.shade600,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      mainButton: TextButton(
                        onPressed: () {
                          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
                          Get.to(() => CartView());
                        },
                        child: const Text(
                          'VIEW CART',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  } catch (e) {
                    onAddToCart();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Add to cart',
                  style: AppTextStyles.buttonMedium.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
    );
  }
}
