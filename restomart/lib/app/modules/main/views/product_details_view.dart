import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../cart/views/cart_view.dart';
import '../../favorites/controllers/favorites_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widgets/product_card.dart';
import '../controllers/home_controller.dart';

class ProductDetailsView extends StatefulWidget {
  final String id;
  final String imagePath;
  final List<String>? imagePaths;
  final String name;
  final double salePrice;
  final double originalPrice;

  const ProductDetailsView({
    super.key,
    required this.id,
    required this.imagePath,
    this.imagePaths,
    required this.name,
    required this.salePrice,
    required this.originalPrice,
  });

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  int quantity = 1;
  final CartController cartController = Get.find<CartController>();

  @override
  void initState() {
    super.initState();
    _addToRecent();
  }

  void _addToRecent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        final prod = WooCommerceProduct(
          id: int.tryParse(widget.id) ?? 0,
          name: widget.name,
          image: widget.imagePath,
          price: widget.salePrice.toInt(),
          originalPrice: widget.originalPrice > widget.salePrice ? widget.originalPrice.toInt() : null,
          isOnSale: widget.originalPrice > widget.salePrice,
          category: 'Grocery', // placeholder
        );
        homeController.addToRecentlyViewed(prod);
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open the link.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showMoreOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Center(child: Text('My Cart', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Get.back();
                  Get.to(() => CartView());
                },
              ),
              ListTile(
                title: const Center(child: Text('Show Gallery', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Get.back();
                  final images = widget.imagePaths ?? [widget.imagePath];
                  Get.dialog(
                    Scaffold(
                      backgroundColor: Colors.black.withValues(alpha: 0.9),
                      body: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: images.length,
                            controller: PageController(initialPage: 0),
                            itemBuilder: (ctx, i) {
                              return InteractiveViewer(
                                panEnabled: true,
                                minScale: 0.5,
                                maxScale: 4,
                                child: images[i].isEmpty
                                  ? const Icon(Icons.image_not_supported, color: Colors.grey)
                                  : images[i].startsWith('http')
                                    ? CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain, placeholder: (c,u) => const SizedBox(), errorWidget: (c,u,e) => const Icon(Icons.broken_image, color: Colors.grey))
                                    : Image.asset(images[i], fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)),
                              );
                            },
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                              onPressed: () => Get.back(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Center(child: Text('Save to Wishlist', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Get.back();
                  final favoritesController = Get.isRegistered<FavoritesController>() 
                      ? Get.find<FavoritesController>() 
                      : Get.put(FavoritesController());
                  if (!favoritesController.isFavorite(widget.name)) {
                    favoritesController.toggleFavorite(
                      id: widget.id,
                      imagePath: widget.imagePath,
                      name: widget.name,
                      salePrice: widget.salePrice,
                      originalPrice: widget.originalPrice,
                      discountPercent: 0,
                    );
                    Get.snackbar('Wishlist', '${widget.name} added to your wishlist.', snackPosition: SnackPosition.BOTTOM);
                  } else {
                    Get.snackbar('Wishlist', '${widget.name} is already in your wishlist.', snackPosition: SnackPosition.BOTTOM);
                  }
                },
              ),
              ListTile(
                title: const Center(child: Text('Share Product Data', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Get.back();
                  Get.snackbar('Share', 'Product data copied: ${widget.name} for Rs. ${widget.salePrice}', snackPosition: SnackPosition.BOTTOM);
                },
              ),
              ListTile(
                title: const Center(child: Text('Share Product Link', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Get.back();
                  final slug = widget.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-$'), '');
                  final url = 'https://restomart.pk/shop/$slug/';
                  Clipboard.setData(ClipboardData(text: url));
                  Get.snackbar('Link Copied', 'Product link copied to clipboard.', snackPosition: SnackPosition.BOTTOM);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Center(child: Text('Cancel', style: TextStyle(fontSize: 16))),
                onTap: () {
                  Get.back();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Main Content (Scrollable) ──────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120), // Space for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Header ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 350,
                  decoration: const BoxDecoration(
                    color: AppColors.surface, // Light grey background
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.spacingXl),
                      child: Builder(
                        builder: (context) {
                          final images = widget.imagePaths ?? [widget.imagePath];
                          return PageView.builder(
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Get.dialog(
                                    Scaffold(
                                      backgroundColor: Colors.black.withValues(alpha: 0.9),
                                      body: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          PageView.builder(
                                            itemCount: images.length,
                                            controller: PageController(initialPage: index),
                                            itemBuilder: (ctx, i) {
                                              return InteractiveViewer(
                                                panEnabled: true,
                                                minScale: 0.5,
                                                maxScale: 4,
                                                child: images[i].isEmpty
                                                  ? const Icon(Icons.image_not_supported, color: Colors.grey)
                                                  : images[i].startsWith('http')
                                                    ? CachedNetworkImage(imageUrl: images[i], fit: BoxFit.contain, placeholder: (c,u) => const SizedBox(), errorWidget: (c,u,e) => const Icon(Icons.broken_image, color: Colors.grey))
                                                    : Image.asset(images[i], fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)),
                                              );
                                            },
                                          ),
                                          Positioned(
                                            top: 40,
                                            right: 20,
                                            child: IconButton(
                                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                              onPressed: () => Get.back(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: index == 0 ? widget.imagePath : '${widget.imagePath}_$index',
                                  child: images[index].isEmpty
                                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                                    : images[index].startsWith('http')
                                      ? CachedNetworkImage(imageUrl: images[index], fit: BoxFit.contain, placeholder: (c,u) => const SizedBox(), errorWidget: (c,u,e) => const Icon(Icons.broken_image, color: Colors.grey))
                                      : Image.asset(images[index], fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // ── Product Info ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.name,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      // ── Availability & Contact ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Availability: ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'In Stock',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Contact & Social Media
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => _launchUrl('tel:+923211655556'),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const FaIcon(FontAwesomeIcons.phone, color: Colors.blue, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _launchUrl('https://wa.me/923211655556'),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppDimensions.spacingLg),

                      // ── Description ────────────────────────────────────────
                      Text(
                        'DESCRIPTION',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Text.rich(
                        TextSpan(
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
                          children: [
                            TextSpan(text: '${widget.name} – Perfect Flavor for Every Meal\n', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
                            TextSpan(text: 'Indulge in the rich and smoky taste of ${widget.name}, now available at Restomart. This versatile product enhances your culinary experience with its unique blend of flavours, making it an essential addition to your pantry. Whether you’re hosting a party or preparing a quick meal, it delivers the perfect balance in every bite. Ideal for any kitchen in Lahore.\n\n'),
                            TextSpan(text: 'Key Features of ${widget.name}\n', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                            const TextSpan(text: '• Rich Flavour: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: 'Adds a bold, savory taste to meals, vegetables, and more.\n'),
                            const TextSpan(text: '• Versatile Use: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: 'Perfect for cooking, marinating, dipping, or as a condiment for your favourite dishes.\n'),
                            const TextSpan(text: '• Convenient Size: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: 'Designed for both family meals and larger gatherings.\n'),
                            const TextSpan(text: '• Premium Ingredients: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: 'Made with high-quality ingredients for a flavourful and authentic experience.\n\n'),
                            TextSpan(text: 'Why Choose Restomart in Lahore for Grocery Products?\n', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                            const TextSpan(text: 'At Restomart, we pride ourselves on offering a wide selection of high-quality products to meet your everyday needs. From flavourful sauces to pantry staples, we stock everything you need. We guarantee premium quality products with every purchase. Don’t wait to elevate your cooking! Visit Restomart today for an unforgettable culinary experience.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── You Might Also Like ────────────────────────────────
                      Text(
                        'YOU MIGHT ALSO LIKE',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 260, // Height for ProductCard
                        child: Obx(() {
                          final homeController = Get.isRegistered<HomeController>() 
                              ? Get.find<HomeController>() 
                              : Get.put(HomeController());
                          
                          if (homeController.allProducts.isEmpty) return const SizedBox.shrink();

                          final currentProduct = homeController.allProducts.firstWhereOrNull((p) => p.id.toString() == widget.id);

                          var recommendations = <WooCommerceProduct>[];

                          if (currentProduct != null) {
                            // Get products in same category
                            recommendations = homeController.allProducts
                                .where((p) => p.id.toString() != widget.id && p.category == currentProduct.category)
                                .toList();
                          } else {
                            // If product not in top 100 (e.g. found via search), try matching by first word
                            final firstWord = widget.name.split(' ').first.toLowerCase();
                            if (firstWord.length > 2) {
                              recommendations = homeController.allProducts
                                  .where((p) => p.id.toString() != widget.id && p.name.toLowerCase().contains(firstWord))
                                  .toList();
                            }
                          }
                          
                          recommendations.shuffle();
                          
                          // If we still don't have enough, fill with random items from all products
                          if (recommendations.length < 4) {
                            var others = homeController.allProducts
                              .where((p) => p.id.toString() != widget.id && !recommendations.contains(p))
                              .toList();
                            others.shuffle();
                            recommendations.addAll(others.take(4 - recommendations.length));
                          }
                          
                          final topRecommendations = recommendations.take(4).toList();

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: topRecommendations.length,
                            itemBuilder: (context, index) {
                              final product = topRecommendations[index];
                              return ProductCard(
                                id: product.id.toString(),
                                imagePath: product.image,
                                name: product.name,
                                salePrice: product.price.toDouble(),
                                originalPrice: product.originalPrice?.toDouble() ?? product.price.toDouble(),
                                discountPercent: product.isOnSale && product.originalPrice != null
                                    ? (((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()
                                    : 0,
                                onAddToCart: () {
                                  final cartController = Get.find<CartController>();
                                  cartController.addToCart(
                                    product.id.toString(),
                                    product.image,
                                    product.name,
                                    product.price.toDouble(),
                                    1,
                                    originalPrice: product.originalPrice?.toDouble() ?? product.price.toDouble(),
                                  );
                                },
                              );
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Top Navigation Icons ───────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
                vertical: AppDimensions.spacingSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconBtn(Icons.close, () => Get.back()),
                  Row(
                    children: [
                      Obx(() {
                        final favoritesController = Get.isRegistered<FavoritesController>() 
                            ? Get.find<FavoritesController>() 
                            : Get.put(FavoritesController());
                        
                        final isFav = favoritesController.isFavorite(widget.name);
                        return _buildIconBtn(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          () {
                            favoritesController.toggleFavorite(
                              id: widget.id,
                              imagePath: widget.imagePath,
                              name: widget.name,
                              salePrice: widget.salePrice,
                              originalPrice: widget.originalPrice,
                              discountPercent: 0,
                            );
                          },
                          color: isFav ? const Color(0xFFE53E3E) : Colors.grey.shade400,
                        );
                      }),
                      const SizedBox(width: 12),
                      _buildIconBtn(Icons.more_vert, () {
                        _showMoreOptionsBottomSheet(context);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Action Bar ──────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Price
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Rs. ${widget.salePrice.toInt()}',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),

                    // Quantity Selector
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 20),
                            onPressed: () {
                              if (quantity > 1) setState(() => quantity--);
                            },
                          ),
                          Text(
                            '$quantity',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            onPressed: () {
                              setState(() => quantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Add to Cart Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            cartController.addToCart(
                              widget.id,
                              widget.imagePath,
                              widget.name,
                              widget.salePrice,
                              quantity,
                              originalPrice: widget.originalPrice,
                            );
                            Get.snackbar(
                              'Added to Cart',
                              '$quantity x ${widget.name} added to your cart.',
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
                          },
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          label: const Text('Add to cart'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
      ),
    );
  }
}
