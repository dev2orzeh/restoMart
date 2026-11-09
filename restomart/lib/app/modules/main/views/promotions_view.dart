import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/product_card.dart';
import '../../cart/controllers/cart_controller.dart';
import 'all_products_view.dart';

class PromotionsView extends StatefulWidget {
  const PromotionsView({super.key});

  @override
  State<PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<PromotionsView> {
  late final PageController _pageController;
  Timer? _autoSwipeTimer;
  int _currentPage = 0;

  final List<Map<String, String>> _banners = [
    {
      'image': 'assets/images/Cheese, oil and beverage combo deals-3.png',
      'title': 'Cheese, Oil & Beverage Combo Deals',
      'tag': 'COMBO OFFER',
      'filter': 'Combo Deals',
    },
    {
      'image': 'assets/images/Elegant navy sale coupon banner-2.png',
      'title': 'Exclusive Coupon Sale & Discount Vouchers',
      'tag': 'COUPON DEALS',
      'filter': 'Weekly Deals',
    },
    {
      'image': 'assets/images/RestoMart special offers banner-1.png',
      'title': 'RestoMart Mega B2B Special Offers',
      'tag': 'SPECIAL OFFERS',
      'filter': 'Weekly Deals',
    },
  ];

  final List<Map<String, dynamic>> _weeklyDeals = [
    {
      'id': 'promo_frozen_1',
      'name': 'RestoMart Special Frozen Food Mega Saver Pack',
      'salePrice': 2850.0,
      'originalPrice': 3500.0,
      'discountPercent': 18,
      'imagePath': 'assets/images/RestoMart-Frozen-Food-Deal-Offer-430x430.png',
    },
    {
      'id': 'promo_oil_1',
      'name': 'Mezan Perfect Frying Oil 16 Ltr Tin',
      'salePrice': 7490.0,
      'originalPrice': 8990.0,
      'discountPercent': 17,
      'imagePath': 'assets/images/B2B-SKU-Mezan-Perfect-Frying-Oil-Tin-16-Ltr-430x430.webp',
    },
    {
      'id': 'promo_sufi_1',
      'name': 'Sufi Frying Oil Can 5 Ltr Mega Saver',
      'salePrice': 2990.0,
      'originalPrice': 3800.0,
      'discountPercent': 21,
      'imagePath': 'assets/images/sufioilCan.webp',
    },
    {
      'id': 'promo_tea_1',
      'name': 'Lipton Yellow Label Tea Bags 100s Pack',
      'salePrice': 1150.0,
      'originalPrice': 1350.0,
      'discountPercent': 15,
      'imagePath': 'assets/images/Lipton-Tea-Bag-–-100pcs-430x430.webp',
    },
  ];

  final List<Map<String, dynamic>> _regularDeals = [
    {
      'id': 'promo_cheese_1',
      'name': 'Adams White Cheese Slices 1kg Pack',
      'salePrice': 1290.0,
      'originalPrice': 1550.0,
      'discountPercent': 17,
      'imagePath': 'assets/images/Adams-Cheese-Slice-White-1kg-430x430.webp',
    },
    {
      'id': 'promo_combo_1',
      'name': 'Cheese & Beverage Ultimate Combo Pack',
      'salePrice': 1850.0,
      'originalPrice': 2450.0,
      'discountPercent': 25,
      'imagePath': 'assets/images/Cheese, oil and beverage combo deals-3.png',
    },
    {
      'id': 'promo_nuts_1',
      'name': 'Premium Dry Fruits Almonds 1kg Gift Pack',
      'salePrice': 2490.0,
      'originalPrice': 3200.0,
      'discountPercent': 22,
      'imagePath': 'assets/images/Almond-1kg-430x430.webp',
    },
    {
      'id': 'promo_bogo_1',
      'name': 'Coca-Cola 1.5L Family Bottle (Buy 1 Get 1)',
      'salePrice': 220.0,
      'originalPrice': 440.0,
      'discountPercent': 50,
      'imagePath': 'assets/images/cocaCola1.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onBannerTap(int index) {
    final bannerFilter = _banners[index]['filter'] ?? 'Weekly Deals';
    Get.to(() => AllProductsView(initialCategory: bannerFilter, pageTitle: bannerFilter, onlyOnSale: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer, color: Color(0xFF25258F), size: 22),
            SizedBox(width: 8),
            Text(
              'Promotions & Deals',
              style: TextStyle(
                color: Color(0xFF25258F),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Auto-Swipeable Banner Carousel ──
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 185,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _banners.length,
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return GestureDetector(
                      onTap: () => _onBannerTap(index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            banner['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF25258F),
                              child: Center(
                                child: Text(
                                  banner['title']!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD54F),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    banner['tag']!,
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Tap to Shop',
                                        style: TextStyle(
                                          color: Color(0xFF25258F),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward, size: 12, color: Color(0xFF25258F)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Carousel Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF25258F) : const Color(0xFFC5CAE9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── SECTION 1: WEEKLY DEALS ──
            _buildSectionHeader(
              title: 'Weekly Deals',
              badge: 'LIMITED TIME',
              badgeColor: const Color(0xFFFFE082),
              onViewAll: () {
                Get.to(() => const AllProductsView(
                      initialCategory: 'Weekly Deals',
                      pageTitle: 'Weekly Deals',
                      onlyOnSale: true,
                    ));
              },
            ),
            const SizedBox(height: 14),
            _buildProductGrid(_weeklyDeals),

            const SizedBox(height: 32),

            // ── SECTION 2: REGULAR DEALS ──
            _buildSectionHeader(
              title: 'Regular Deals',
              badge: 'EVERYDAY SAVERS',
              badgeColor: const Color(0xFFC5CAE9),
              onViewAll: () {
                Get.to(() => const AllProductsView(
                      initialCategory: 'Regular Deals',
                      pageTitle: 'Regular Deals',
                      onlyOnSale: true,
                    ));
              },
            ),
            const SizedBox(height: 14),
            _buildProductGrid(_regularDeals),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String badge,
    required Color badgeColor,
    required VoidCallback onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF25258F),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onViewAll,
          child: const Row(
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF25258F),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF25258F)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return ProductCard(
          id: item['id']!,
          imagePath: item['imagePath']!,
          name: item['name']!,
          salePrice: item['salePrice'] as double,
          originalPrice: item['originalPrice'] as double,
          discountPercent: item['discountPercent'] as int,
          onAddToCart: () {
            final cartController = Get.isRegistered<CartController>()
                ? Get.find<CartController>()
                : Get.put(CartController());
            cartController.addToCart(
              item['id']!,
              item['imagePath']!,
              item['name']!,
              item['salePrice'] as double,
              1,
              originalPrice: item['originalPrice'] as double,
            );
          },
        );
      },
    );
  }
}
