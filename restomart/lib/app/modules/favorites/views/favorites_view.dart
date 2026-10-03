import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/product_card.dart';
import '../controllers/favorites_controller.dart';
import '../../cart/controllers/cart_controller.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    // Attempt to get the controller, or create if not present
    final FavoritesController controller = Get.isRegistered<FavoritesController>() 
        ? Get.find<FavoritesController>() 
        : Get.put(FavoritesController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text('My Favorites', style: AppTextStyles.headingMedium),
      ),
      body: Obx(() {
        if (controller.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No favorites yet!',
                  style: AppTextStyles.headingMedium.copyWith(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on any product\nto save it here.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }

        final items = controller.favorites.values.toList();
        return GridView.builder(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.60,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            return ProductCard(
              id: product.id,
              width: null,
              margin: EdgeInsets.zero,
              imagePath: product.imagePath,
              name: product.name,
              salePrice: product.salePrice,
              originalPrice: product.originalPrice,
              discountPercent: product.discountPercent,
              onAddToCart: () {
                final cartController = Get.find<CartController>();
                cartController.addToCart(
                  product.id,
                  product.imagePath,
                  product.name,
                  product.salePrice,
                  1,
                );
              }, 
            );
          },
        );
      }),
    );
  }
}
