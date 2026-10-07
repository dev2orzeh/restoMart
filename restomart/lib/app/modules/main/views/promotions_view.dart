import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/product_card.dart';
import '../../cart/controllers/cart_controller.dart';

class PromotionsView extends StatefulWidget {
  const PromotionsView({super.key});

  @override
  State<PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<PromotionsView> {
  late final PageController _pageController;
  Timer? _autoSwipeTimer;
  int _currentPage = 0;
  String _selectedTab = 'All';
  final ScrollController _scrollController = ScrollController();

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
      'filter': 'Special Offers',
    },
  ];

  final List<String> _tabs = [
    'All',
    'Weekly Deals',
    'Regular Deals',
    'Combo Deals',
    'Buy 1 Get 1',
    'Special Offers',
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabSelected(String tabName) {
    setState(() {
      _selectedTab = tabName;
    });
  }

  void _onBannerTap(int index) {
    final bannerFilter = _banners[index]['filter'] ?? 'All';
    _onTabSelected(bannerFilter);
    Get.snackbar(
      _banners[index]['tag'] ?? 'Special Offer',
      'Applied filter: ${_banners[index]['title']}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF25258F),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  List<Map<String, dynamic>> _getPromoProducts() {
    final List<Map<String, dynamic>> allPromos = [
      {
        'id': 'promo_combo_1',
        'name': 'Cheese & Beverage Ultimate Combo Pack',
        'salePrice': 1850.0,
        'originalPrice': 2450.0,
        'discountPercent': 25,
        'imagePath': 'assets/images/Cheese, oil and beverage combo deals-3.png',
        'category': 'Combo Deals',
        'tag': 'Buy 1 Get 1',
      },
      {
        'id': 'promo_oil_1',
        'name': 'Mezan Perfect Frying Oil 16 Ltr Tin',
        'salePrice': 7490.0,
        'originalPrice': 8990.0,
        'discountPercent': 17,
        'imagePath': 'assets/images/B2B-SKU-Mezan-Perfect-Frying-Oil-Tin-16-Ltr-430x430.webp',
        'category': 'Weekly Deals',
        'tag': 'Weekly Deals',
      },
      {
        'id': 'promo_cheese_1',
        'name': 'Adams White Cheese Slices 1kg Pack',
        'salePrice': 1290.0,
        'originalPrice': 1550.0,
        'discountPercent': 17,
        'imagePath': 'assets/images/Adams-Cheese-Slice-White-1kg-430x430.webp',
        'category': 'Regular Deals',
        'tag': 'Regular Deals',
      },
      {
        'id': 'promo_bev_1',
        'name': 'Chilled Beverages Assortment Pack (12 Pcs)',
        'salePrice': 990.0,
        'originalPrice': 1400.0,
        'discountPercent': 30,
        'imagePath': 'assets/images/Chilled Beverage Assortment with Ice.png',
        'category': 'Buy 1 Get 1',
        'tag': 'Buy 1 Get 1',
      },
      {
        'id': 'promo_sufi_1',
        'name': 'Sufi Frying Oil Can 5 Ltr Mega Saver',
        'salePrice': 2990.0,
        'originalPrice': 3800.0,
        'discountPercent': 21,
        'imagePath': 'assets/images/sufioilCan.webp',
        'category': 'Special Offers',
        'tag': 'Special Offers',
      },
      {
        'id': 'promo_nuts_1',
        'name': 'Premium Dry Fruits Almonds 1kg Gift Pack',
        'salePrice': 2490.0,
        'originalPrice': 3200.0,
        'discountPercent': 22,
        'imagePath': 'assets/images/Almond-1kg-430x430.webp',
        'category': 'Regular Deals',
        'tag': 'Regular Deals',
      },
      {
        'id': 'promo_bogo_1',
        'name': 'Coca-Cola 1.5L Family Bottle (Buy 1 Get 1)',
        'salePrice': 220.0,
        'originalPrice': 440.0,
        'discountPercent': 50,
        'imagePath': 'assets/images/cocaCola1.jpg',
        'category': 'Buy 1 Get 1',
        'tag': 'Buy 1 Get 1',
      },
      {
        'id': 'promo_tea_1',
        'name': 'Lipton Yellow Label Tea Bags 100s Pack',
        'salePrice': 1150.0,
        'originalPrice': 1350.0,
        'discountPercent': 15,
        'imagePath': 'assets/images/Lipton-Tea-Bag-–-100pcs-430x430.webp',
        'category': 'Weekly Deals',
        'tag': 'Weekly Deals',
      },
    ];

    if (_selectedTab == 'All') {
      return allPromos;
    }

    return allPromos.where((p) {
      final cat = (p['category'] ?? '').toString();
      final tag = (p['tag'] ?? '').toString();
      return cat == _selectedTab || tag == _selectedTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final promoProducts = _getPromoProducts();

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
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clickable Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _onTabSelected(tab),
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ] : [],
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF25258F),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Auto-Swipeable Banner Carousel (3 Banners requested by user)
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
                child: Stack(
                  children: [
                    PageView.builder(
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

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

            const SizedBox(height: 20),

            // Featured Promotional Offers Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedTab == 'All' ? 'Featured Promotional Deals' : 'Promotions: $_selectedTab',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () => _onTabSelected('All'),
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
                      Icon(Icons.arrow_forward, size: 14, color: Color(0xFF25258F)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4 Clickable Featured Promotion Cards
            Row(
              children: [
                Expanded(
                  child: _buildClickableDealCard(
                    title: 'Buy 2 Get 1 Free',
                    subtitle: 'Chilled Beverages Assortment',
                    imagePath: 'assets/images/beverages.webp',
                    badge: 'BOGO OFFER',
                    onTap: () => _onTabSelected('Buy 1 Get 1'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildClickableDealCard(
                    title: 'Flat 20% Off',
                    subtitle: 'Cooking Oils & Tin Savers',
                    imagePath: 'assets/images/sufioilCan.webp',
                    badge: 'WEEKLY DEAL',
                    onTap: () => _onTabSelected('Weekly Deals'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildClickableDealCard(
                    title: 'Combo Savers',
                    subtitle: 'Cheese & Beverage Deals',
                    imagePath: 'assets/images/CheeseCategory.png',
                    badge: 'COMBO DEAL',
                    onTap: () => _onTabSelected('Combo Deals'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildClickableDealCard(
                    title: 'Regular Deals',
                    subtitle: 'Dry Fruits & Kitchen Stock',
                    imagePath: 'assets/images/dryFruits.webp',
                    badge: 'SPECIAL',
                    onTap: () => _onTabSelected('Regular Deals'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Live Promotional Products Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Color(0xFF25258F), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Special Offer Products (${promoProducts.length})',
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Grid of Clickable Products with Add to Cart
            promoProducts.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('No promotional items found in $_selectedTab.', style: TextStyle(color: Colors.grey.shade700)),
                      TextButton(
                        onPressed: () => _onTabSelected('All'),
                        child: const Text('Show All Deals'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: promoProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.64,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = promoProducts[index];
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
                ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableDealCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25258F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF25258F)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                imagePath,
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: const Center(
                child: Text(
                  'Explore Offers',
                  style: TextStyle(color: Color(0xFF25258F), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
