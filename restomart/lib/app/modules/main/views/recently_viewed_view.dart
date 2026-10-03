import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import 'product_details_view.dart';
import '../../cart/controllers/cart_controller.dart';

class RecentlyViewedView extends StatelessWidget {
  const RecentlyViewedView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF25258F)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Recently Viewed',
          style: TextStyle(color: Color(0xFF25258F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.recentlyViewed.isEmpty) {
          return const Center(
            child: Text(
              'No recently viewed products',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.52,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.recentlyViewed.length,
          itemBuilder: (context, index) {
            final product = controller.recentlyViewed[index];
            return _buildProductCard(
              product.id.toString(),
              product.name,
              product.price,
              product.image,
              product.isOnSale,
              originalPrice: product.originalPrice,
            );
          },
        );
      }),
    );
  }

  Widget _buildProductCard(
    String id,
    String name,
    int price,
    String image,
    bool isOnSale, {
    int? originalPrice,
  }) {
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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
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
                          ? Image.network(image,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.image_not_supported, color: Colors.grey))
                          : Image.asset(image, fit: BoxFit.contain),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(Icons.favorite_border,
                      color: Colors.grey.shade400, size: 20),
                ),
                if (isOnSale)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('On sale',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF25258F))),
                  const SizedBox(height: 4),
                  Text('1 item',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs. $price',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF25258F))),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text('Rs. $originalPrice',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (Get.isRegistered<CartController>()) {
                          Get.find<CartController>().addToCart(
                            id,
                            image,
                            name,
                            price.toDouble(),
                            1,
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
                      icon: const Icon(Icons.shopping_cart_outlined,
                          size: 16, color: Colors.white),
                      label: const Text('Add to cart',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25258F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
