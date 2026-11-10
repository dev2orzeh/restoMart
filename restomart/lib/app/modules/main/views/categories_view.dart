import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import 'all_products_view.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF25258F);
  static const Color primaryYellow = Color(0xFFFFC400);
  static const Color darkText = Color(0xFF20283A);
  static const Color secondaryText = Color(0xFF8B92A5);
  static const Color pageBackground = Color(0xFFF8F9FC);

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Rice',
      'subtitle': 'Basmati, steam & sella rice',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Rice.png',
      'bgColor': const Color(0xFFFFF8E1),
      'targetCategory': 'Rice',
      'isFullImage': true,
    },
    {
      'title': 'Flour',
      'subtitle': 'Corn flour, maida & wheat flour',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Flour.png',
      'bgColor': const Color(0xFFEEF7FF),
      'targetCategory': 'Flour',
      'isFullImage': true,
    },
    {
      'title': 'Cheese',
      'subtitle': 'Fresh & premium cheese',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png',
      'bgColor': const Color(0xFFEEF7FF),
      'targetCategory': 'Cheese',
      'isFullImage': true,
    },
    {
      'title': 'Beverages',
      'subtitle': 'Drinks, juices & refreshments',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/02_Beverages.png',
      'bgColor': const Color(0xFFFFF8E1),
      'targetCategory': 'Beverage',
      'isFullImage': true,
    },
    {
      'title': 'Cooking Oils',
      'subtitle': 'Oils for professional kitchens',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/03_Cooking_Oils.png',
      'bgColor': const Color(0xFFFFF8E1),
      'targetCategory': 'Oil',
      'isFullImage': true,
    },
    {
      'title': 'Milks',
      'subtitle': 'Fresh & packaged milk',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/04_Milks.png',
      'bgColor': const Color(0xFFEEF7FF),
      'targetCategory': 'Milk',
      'isFullImage': true,
    },
    {
      'title': 'Packaging Boxes',
      'subtitle': 'Food packaging solutions',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/05_Packaging_Materials.png',
      'bgColor': const Color(0xFFFFF1F3),
      'targetCategory': 'Packaging',
      'isFullImage': true,
    },
    {
      'title': 'Tea',
      'subtitle': 'Tea & hot beverages',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/06_Tea.png',
      'bgColor': const Color(0xFFF0FAF4),
      'targetCategory': 'Tea',
      'isFullImage': true,
    },
    {
      'title': 'Spices',
      'subtitle': 'Seasonings & kitchen spices',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/07_Spices.png',
      'bgColor': const Color(0xFFFFF3E8),
      'targetCategory': 'Masala',
      'isFullImage': true,
    },
    {
      'title': 'Dry Fruits',
      'subtitle': 'Nuts & dried fruits',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/08_Dry_Fruits.png',
      'bgColor': const Color(0xFFFFF2E9),
      'targetCategory': 'Dry Fruits',
      'isFullImage': true,
    },
    {
      'title': 'Cleaning Products',
      'subtitle': 'Restaurant cleaning essentials',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/09_Cleaning_Products.png',
      'bgColor': const Color(0xFFEDF9FA),
      'targetCategory': 'Cleaning',
      'isFullImage': true,
    },
    {
      'title': 'Baking Products',
      'subtitle': 'Baking essentials & supplies',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/10_Baking_Products.png',
      'bgColor': const Color(0xFFFFF5E9),
      'targetCategory': 'Baking',
      'isFullImage': true,
    },
    {
      'title': 'Canned Products',
      'subtitle': 'Ready-to-use canned goods',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/11_Canned_Products.png',
      'bgColor': const Color(0xFFFFF8E1),
      'targetCategory': 'Canned',
      'isFullImage': true,
    },
    {
      'title': 'Stationary',
      'subtitle': 'Office & restaurant stationary',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/12_Stationery.png',
      'bgColor': const Color(0xFFF9F5F0),
      'targetCategory': 'Stationary',
      'isFullImage': true,
    },
    {
      'title': 'Beauty Products',
      'subtitle': 'Anua, Avene, Joseon & more',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/13_Beauty_Products.png',
      'bgColor': const Color(0xFFFFF5E9),
      'targetCategory': 'anua',
      'isFullImage': true,
    },
    {
      'title': 'Kitchen Accessories',
      'subtitle': 'Pots, pans & kitchen tools',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Kitchen_Accessories.png',
      'bgColor': const Color(0xFFEDF9FA),
      'targetCategory': 'Kitchen Accessories',
      'isFullImage': true,
    },
    {
      'title': 'Sauces & Condiments',
      'subtitle': 'Bulk ketchup, mayo & sauces',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Sauces.png',
      'bgColor': const Color(0xFFFFF1F3),
      'targetCategory': 'Sauce',
      'isFullImage': true,
    },
    {
      'title': 'Coffee',
      'subtitle': 'Coffee beans & instant',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Coffee.png',
      'bgColor': const Color(0xFFFFF5E9),
      'targetCategory': 'Coffee',
      'isFullImage': true,
    },
    {
      'title': 'Disposables',
      'subtitle': 'Paper cups, straws & plates',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Disposables.png',
      'bgColor': const Color(0xFFF9F5F0),
      'targetCategory': 'Disposable',
      'isFullImage': true,
    },
    {
      'title': 'Chocolates',
      'subtitle': 'Bulk baking & retail chocolates',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Chocolates.png',
      'bgColor': const Color(0xFFFFF3E8),
      'targetCategory': 'Chocolate',
      'isFullImage': true,
    },
    {
      'title': 'Sweets & Desserts',
      'subtitle': 'Candies, jellies & sweets',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Sweets.png',
      'bgColor': const Color(0xFFFFF5E9),
      'targetCategory': 'Sweet',
      'isFullImage': true,
    },
    {
      'title': 'Tissues & Hygiene',
      'subtitle': 'Napkins, wipes & hygiene',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Tissues_and_Hygiene.png',
      'bgColor': const Color(0xFFEEF7FF),
      'targetCategory': 'Tissues',
      'isFullImage': true,
    },
    {
      'title': 'Fragrances',
      'subtitle': 'Air fresheners & scents',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Fragrances.png',
      'bgColor': const Color(0xFFF0FAF4),
      'targetCategory': 'Fragrance',
      'isFullImage': true,
    },
    {
      'title': 'Footwear',
      'subtitle': 'Chef shoes & kitchen footwear',
      'image': 'assets/images/RestoMart_All_Category_Images_430x430/Footwear.png',
      'bgColor': const Color(0xFFFFF8E1),
      'targetCategory': 'Footwear',
      'isFullImage': true,
    },
  ];

  // ============================================================
  // FILTERED CATEGORIES
  // ============================================================

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) {
      return _categories;
    }

    final query = _searchQuery.toLowerCase().trim();

    return _categories.where((category) {
      final title = category['title'].toString().toLowerCase();
      final subtitle = category['subtitle'].toString().toLowerCase();

      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header: "Shop Categories" ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Shop Categories',
                      style: TextStyle(
                        color: Color(0xFF1B1B3A),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  // ── Categories Header Banner Asset ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/categories_header.jpeg',
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // ── Search Bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: pageBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEAECF2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: primaryBlue,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: secondaryText,
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // ── Section Title: Shop by Category ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shop by Category',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_filteredCategories.length} categories',
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // CATEGORY GRID
            // ====================================================
            if (_filteredCategories.isEmpty)
              SliverFillRemaining(
                child: _buildEmptySearch(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = _filteredCategories[index];
                      return _buildCategoryCard(category);
                    },
                    childCount: _filteredCategories.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final title = (category['title'] as String?) ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final targetCategory = category['targetCategory'] ?? category['title'];
          debugPrint('Selected category: $targetCategory');
          Get.to(() => AllProductsView(initialCategory: targetCategory as String));
        },
        child: Ink(
          decoration: BoxDecoration(
            color: category['bgColor'] as Color? ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.04),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                (category['image'] as String).startsWith('http')
                    ? Image.network(
                        category['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.inventory_2_outlined, color: secondaryText, size: 45),
                        ),
                      )
                    : Image.asset(
                        category['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.inventory_2_outlined, color: secondaryText, size: 45),
                        ),
                      ),
                // Bottom category name label
                if (title.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY SEARCH SCREEN
  // ============================================================

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 35),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // =================================================
            // ICON
            // =================================================
            Container(
              width: 82,
              height: 82,

              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E1),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.search_off_rounded,
                color: primaryYellow,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // TITLE
            // =================================================
            const Text(
              'No category found',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: darkText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            // =================================================
            // MESSAGE
            // =================================================
            Text(
              'We couldn\'t find a category matching "$_searchQuery".',
              textAlign: TextAlign.center,

              style: const TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // CLEAR SEARCH
            // =================================================
            TextButton.icon(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                });
              },

              icon: const Icon(
                Icons.refresh_rounded,
                color: primaryBlue,
                size: 18,
              ),

              label: const Text(
                'Clear Search',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
