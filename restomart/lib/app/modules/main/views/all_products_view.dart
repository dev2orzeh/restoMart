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
    // 1. Grab categories from HomeController and add "All"
    final homeController = Get.isRegistered<HomeController>() ? Get.find<HomeController>() : Get.put(HomeController());
    _categories = [
      {'id': 0, 'name': 'All Products'},
      ...homeController.categories
    ];

    // 2. Select initial category if provided
    if (widget.initialCategory != null) {
      final initialStr = widget.initialCategory!.toLowerCase();
      final idx = _categories.indexWhere((c) {
        final catName = (c['name'] as String).toLowerCase();
        final decodedName = catName.replaceAll('&amp;', '&');
        return decodedName.contains(initialStr) || initialStr.contains(decodedName) || 
               decodedName.replaceAll('s', '') == initialStr.replaceAll('s', '');
      });
      if (idx != -1) {
        _selectedCategoryIndex = idx;
      } else {
        // Fallback: If it's a custom keyword (e.g. 'anua', 'tirtir') that isn't a direct WC category,
        // we use it as the search query to filter the products list.
        _searchQuery = widget.initialCategory!;
        _searchController.text = widget.initialCategory!;
      }
    }

    // 3. Fetch products
    _fetchProducts();
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (_isLoading || (!_hasMore && loadMore)) return;

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
      final categoryId = _categories[_selectedCategoryIndex]['id'] as int;
      final newProducts = await WooCommerceApiService.getProducts(
        page: _currentPage,
        perPage: 20,
        categoryId: categoryId == 0 ? null : categoryId.toString(),
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          _products.addAll(newProducts);
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching products in AllProductsView: $e');
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
        title: Text(
          _categories.isNotEmpty ? _categories[_selectedCategoryIndex]['name'] : 'All Products', 
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      _selectedCategoryIndex = 0; // Automatically switch to "All Products" tab so it searches globally
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
                    _selectedCategoryIndex = 0; // Automatically switch to "All Products" tab so it searches globally
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
      padding: const EdgeInsets.all(20),
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
