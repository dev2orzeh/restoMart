import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../widgets/product_card.dart';
import '../controllers/home_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:developer';
import 'dart:async';

class AllProductsView extends StatefulWidget {
  final String? initialCategory;
  final bool autoFocusSearch;
  const AllProductsView({super.key, this.initialCategory, this.autoFocusSearch = false});

  @override
  State<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<AllProductsView> {
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _categories = [];
  int _selectedCategoryIndex = 0;
  
  List<dynamic> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int _fetchId = 0; // Tracks the current active fetch request to prevent race conditions

  String _selectedSort = 'default';
  final List<Map<String, String>> _sortOptions = [
    {'value': 'default', 'label': 'Default sorting'},
    {'value': 'popularity', 'label': 'Sort by popularity'},
    {'value': 'date', 'label': 'Sort by latest'},
    {'value': 'price_asc', 'label': 'Sort by price: low to high'},
    {'value': 'price_desc', 'label': 'Sort by price: high to low'},
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _initData() {
    // 1. Define curated categories to match CategoriesView exactly
    // 1. Define curated categories with exact WooCommerce IDs to prevent string-matching bugs
    final curated = [
      {'title': 'Cheese', 'target': 'Cheese', 'id': 354},
      {'title': 'Beverages', 'target': 'Beverage', 'id': 18},
      {'title': 'Cooking Oils', 'target': 'Oil', 'id': 355},
      {'title': 'Milks', 'target': 'Milk', 'id': 60}, // 60 is Dairy Milk, not 1043 (Makeup Milk)
      {'title': 'Packaging Boxes', 'target': 'Packaging', 'id': 50},
      {'title': 'Tea', 'target': 'Tea', 'id': 59},
      {'title': 'Spices', 'target': 'Masala', 'id': 350},
      {'title': 'Dry Fruits', 'target': 'Dry Fruits', 'id': 357},
      {'title': 'Cleaning Products', 'target': 'Cleaning', 'id': 52},
      {'title': 'Baking Products', 'target': 'Baking', 'id': 356},
      {'title': 'Canned Products', 'target': 'Canned', 'id': 20},
      {'title': 'Stationary', 'target': 'Stationary', 'id': 346},
      {'title': 'Beauty Products', 'target': 'anua', 'id': 1011}, // 1011 is Makeup
      {'title': 'Kitchen Accessories', 'target': 'Kitchen Accessories', 'id': 221},
      {'title': 'Sauces & Condiments', 'target': 'Sauce', 'id': 23},
      {'title': 'Coffee', 'target': 'Coffee', 'id': 337},
      {'title': 'Disposables', 'target': 'Disposable', 'id': 220},
      {'title': 'Chocolates', 'target': 'Chocolate', 'id': 40},
      {'title': 'Sweets & Desserts', 'target': 'Sweet', 'id': 336},
      {'title': 'Tissues & Hygiene', 'target': 'Tissues', 'id': 345},
      {'title': 'Fragrances', 'target': 'Fragrance', 'id': 41},
      {'title': 'Footwear', 'target': 'Footwear', 'id': 1247},
    ];

    _categories = [{'id': 0, 'name': 'All Products', 'target': null}];
    
    for (var c in curated) {
      _categories.add({
        'id': c['id'], 
        'name': c['title'],
        'target': c['target'],
      });
    }

    // 2. Select initial category if provided
    if (widget.initialCategory != null) {
      final initialStr = widget.initialCategory!.toLowerCase();
      final idx = _categories.indexWhere((c) {
        final target = (c['target'] as String?)?.toLowerCase() ?? '';
        final name = (c['name'] as String).toLowerCase();
        return target == initialStr || name.contains(initialStr) || initialStr.contains(name) ||
               name.replaceAll('s', '') == initialStr.replaceAll('s', '');
      });
      
      if (idx != -1) {
        _selectedCategoryIndex = idx;
      } else {
        // Fallback: If completely unknown, just search for it in All Products
        _searchQuery = widget.initialCategory!;
        _searchController.text = widget.initialCategory!;
      }
    }

    // 3. Fetch products
    _fetchProducts();
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    // Only block if we are loading MORE for the current page, or if there's no more to load
    if (loadMore && (_isLoading || !_hasMore)) return;
    
    final currentFetchId = ++_fetchId;

    if (!loadMore) {
      setState(() {
        _currentPage = 1;
        _products.clear();
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final currentCategory = _categories[_selectedCategoryIndex];
      final categoryId = currentCategory['id'] as int;
      final targetKeyword = currentCategory['target'] as String?;

      String? finalSearchQuery = _searchQuery.isEmpty ? null : _searchQuery;
      
      // If we are on a category tab that has no WooCommerce ID, we use its target keyword as the search query
      if (categoryId == 0 && targetKeyword != null && _searchQuery.isEmpty) {
        finalSearchQuery = targetKeyword;
      }
      
      String? orderBy;
      String? order;
      if (_selectedSort == 'popularity') {
        orderBy = 'popularity';
      } else if (_selectedSort == 'date') {
        orderBy = 'date';
        order = 'desc';
      } else if (_selectedSort == 'price_asc') {
        orderBy = 'price';
        order = 'asc';
      } else if (_selectedSort == 'price_desc') {
        orderBy = 'price';
        order = 'desc';
      }

      final newProducts = await WooCommerceApiService.getProducts(
        page: _currentPage,
        perPage: finalSearchQuery != null ? 50 : 20,
        categoryId: categoryId == 0 ? null : categoryId.toString(),
        searchQuery: finalSearchQuery,
        orderBy: orderBy,
        order: order,
      );

      setState(() {
        if (currentFetchId != _fetchId) return; // Discard results if a newer request was started
        
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final words = q.split(RegExp(r'\s+'));
            
            // Separate into: title matches vs description-only matches
            final List<dynamic> titleMatches = [];
            final List<dynamic> descriptionOnlyMatches = [];
            
            for (final product in newProducts) {
              final name = (product['name']?.toString() ?? '').toLowerCase();
              // Check if ANY search word appears in the product title
              final hasWordInTitle = words.any((w) => 
                name.split(RegExp(r'[\s\-_,.()/]+')).any((titleWord) => titleWord.startsWith(w) || w.startsWith(titleWord))
              );
              
              if (hasWordInTitle) {
                titleMatches.add(product);
              } else {
                descriptionOnlyMatches.add(product);
              }
            }
            
            // Sort title matches: intelligent AI sorting for 'pure' matches
            titleMatches.sort((a, b) {
              final aName = (a['name']?.toString() ?? '').toLowerCase();
              final bName = (b['name']?.toString() ?? '').toLowerCase();
              
              // Priority 1: Exact match with query
              if (aName == q && bName != q) return -1;
              if (bName == q && aName != q) return 1;

              // Priority 2: Name starts with query
              final aStarts = aName.startsWith(q) ? 1 : 0;
              final bStarts = bName.startsWith(q) ? 1 : 0;
              if (aStarts != bStarts) return bStarts.compareTo(aStarts);
              
              // Priority 3: Has exact word match
              final aExact = aName.split(RegExp(r'[\s\-_,.()/]+')).any((w) => words.contains(w)) ? 1 : 0;
              final bExact = bName.split(RegExp(r'[\s\-_,.()/]+')).any((w) => words.contains(w)) ? 1 : 0;
              if (aExact != bExact) return bExact.compareTo(aExact);
              
              // Priority 4: Length of the name (shorter names are usually purer/closer to the actual query)
              return aName.length.compareTo(bName.length);
            });
            
            // Show ONLY title matches, hide description-only matches completely
            newProducts.clear();
            newProducts.addAll(titleMatches);
          }
          _products.addAll(newProducts);
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching products in AllProductsView: $e');
      if (currentFetchId != _fetchId) return; // Discard errors for old requests
      
      Get.snackbar(
        'Network Error', 
        'Could not load products. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEBEE),
        colorText: const Color(0xFFC62828),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchProducts(loadMore: true);
    }
  }

  void _onCategoryTapped(int index) {
    if (_selectedCategoryIndex == index) return;
    setState(() {
      _selectedCategoryIndex = index;
      _searchQuery = '';
      _searchController.clear();
    });
    _fetchProducts(loadMore: false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Aesthetic Category Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categories.isNotEmpty ? _categories[_selectedCategoryIndex]['name'] : 'All Products', 
                  style: const TextStyle(
                    color: Color(0xFF20283A),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse premium items for your restaurant',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  setState(() {
                    _searchQuery = value.trim();
                    if (_searchQuery.isNotEmpty) {
                      // Removed forced switch to "All Products" so users can search within the current category tab.
                    }
                  });
                  _fetchProducts(loadMore: false);
                });
              },
              onSubmitted: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                setState(() {
                  _searchQuery = value.trim();
                  if (_searchQuery.isNotEmpty) {
                    // Removed forced switch to "All Products" so users can search within the current category tab.
                  }
                });
                _fetchProducts(loadMore: false);
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _fetchProducts(loadMore: false);
                        },
                      ) 
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          // ── Sticky Categories Bar ──
          if (_categories.length > 1)
            Container(
              height: 50,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => _onCategoryTapped(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? Colors.red : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _categories[index]['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.red : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1, color: Colors.black12),
          
          // ── Sorting Dropdown ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<String>(
                  value: _selectedSort,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedSort) {
                      setState(() {
                        _selectedSort = value;
                      });
                      _fetchProducts(loadMore: false);
                    }
                  },
                ),
              ],
            ),
          ),
          
          // ── Products Grid ──
          Expanded(
            child: _products.isEmpty && _isLoading
                ? _buildInitialLoadingShimmer()
                : _products.isEmpty && !_isLoading
                    ? const Center(child: Text("No products found in this category."))
                    : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60, // Match HomeView ProductCard aspect ratio
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length + (_hasMore ? 2 : 0), // Add 2 slots for bottom loading shimmer
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          // Bottom loading shimmer blocks
          return _buildProductShimmer();
        }

        final product = _products[index];
        final images = product['images'] as List<dynamic>?;
        final imageUrl = (images != null && images.isNotEmpty) ? images[0]['src'] : '';
        
        final imagesList = images != null 
          ? images.map((e) => e['src'].toString()).toList() 
          : <String>[];

        final regularPrice = double.tryParse(product['regular_price'].toString()) ?? 0.0;
        final salePrice = double.tryParse(product['sale_price'].toString()) ?? 0.0;
        final actualPrice = double.tryParse(product['price'].toString()) ?? 0.0;
        
        final hasDiscount = salePrice > 0 && salePrice < regularPrice;
        final displayedOriginalPrice = hasDiscount ? regularPrice : actualPrice;
        
        int discountPercent = 0;
        if (hasDiscount && regularPrice > 0) {
          discountPercent = (((regularPrice - salePrice) / regularPrice) * 100).round();
        }

        return ProductCard(
          id: product['id'].toString(),
          width: null, // Let grid constraints dictate width
          margin: EdgeInsets.zero,
          imagePath: imageUrl,
          imagePaths: imagesList,
          name: product['name'] ?? 'Unknown',
          salePrice: actualPrice,
          originalPrice: displayedOriginalPrice,
          discountPercent: discountPercent,
          onAddToCart: () {}, // Handled inside ProductCard
        );
      },
    );
  }

  Widget _buildInitialLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 skeleton cards initially
      itemBuilder: (context, index) => _buildProductShimmer(),
    );
  }

  Widget _buildProductShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16)
        ),
      ),
    );
  }
}
