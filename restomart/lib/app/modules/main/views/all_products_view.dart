import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../widgets/product_card.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:developer';
import 'dart:async';
import 'search_view.dart';

class AllProductsView extends StatefulWidget {
  final String? initialCategory;
  final String? initialCategoryId;
  final String? pageTitle;
  final bool autoFocusSearch;
  final bool onlyOnSale;
  const AllProductsView({
    super.key,
    this.initialCategory,
    this.initialCategoryId,
    this.pageTitle,
    this.autoFocusSearch = false,
    this.onlyOnSale = false,
  });

  @override
  State<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<AllProductsView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  String? _currentTitle;
  
  List<dynamic> _categories = [];
  int _selectedCategoryIndex = 0;
  
  List<dynamic> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  int _fetchId = 0; // Tracks the current active fetch request to prevent race conditions

  String _selectedSort = 'default';
  final List<Map<String, String>> _sortOptions = [
    {'value': 'default', 'label': 'Default'},
    {'value': 'price_asc', 'label': 'Price: Low to High'},
    {'value': 'price_desc', 'label': 'Price: High to Low'},
  ];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _debounce;

  bool _onlyOnSale = false;

  @override
  void initState() {
    super.initState();
    _onlyOnSale = widget.onlyOnSale || (widget.initialCategory?.toLowerCase().contains('deal') ?? false) || (widget.initialCategory?.toLowerCase().contains('sale') ?? false);
    _scrollController.addListener(_onScroll);
    _initData();
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  void _initData() {
    // 1. Define curated categories with exact WooCommerce IDs to prevent string-matching bugs
    final curated = [
      {'title': 'Deals & Promotions', 'target': 'deals', 'id': -1},
      {'title': 'Rice', 'target': 'Rice', 'id': 366},
      {'title': 'Flour', 'target': 'Flour', 'id': 365},
      {'title': 'Pulses & Daalain', 'target': 'Daal', 'id': 367},
      {'title': 'Cheese', 'target': 'Cheese', 'id': 354},
      {'title': 'Beverages', 'target': 'Beverage', 'id': '18,604,223,349,337,59'},
      {'title': 'Cooking Oils', 'target': 'Oil', 'id': 355},
      {'title': 'Milks', 'target': 'Milk', 'id': 60}, // 60 is Dairy Milk, not 1043 (Makeup Milk)
      {'title': 'Packaging Boxes', 'target': 'Packaging', 'id': '50,220,330'},
      {'title': 'Tea', 'target': 'Tea', 'id': 59},
      {'title': 'Spices', 'target': 'Masala', 'id': 350},
      {'title': 'Dry Fruits', 'target': 'Dry Fruits', 'id': 357},
      {'title': 'Cleaning Products', 'target': 'Cleaning', 'id': '52,34,345,347,603,348'},
      {'title': 'Baking Products', 'target': 'Baking', 'id': 356},
      {'title': 'Canned Products', 'target': 'Canned', 'id': '20,1220'},
      {'title': 'Stationary', 'target': 'Stationary', 'id': 346},
      {'title': 'Beauty Products', 'target': 'anua', 'id': 1011}, // 1011 is Makeup
      {'title': 'Kitchen Accessories', 'target': 'Kitchen Accessories', 'id': 221},
      {'title': 'Sauces & Condiments', 'target': 'Sauce', 'id': '23,30,224'},
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
    if (widget.initialCategoryId != null && widget.initialCategoryId!.isNotEmpty && widget.initialCategoryId != '0') {
      final targetId = widget.initialCategoryId!;
      final idx = _categories.indexWhere((c) => c['id']?.toString() == targetId);
      if (idx != -1) {
        _selectedCategoryIndex = idx;
      } else {
        _categories.add({
          'id': targetId,
          'name': widget.initialCategory ?? widget.pageTitle ?? 'Category',
          'target': widget.initialCategory,
        });
        _selectedCategoryIndex = _categories.length - 1;
      }
    } else if (widget.initialCategory != null) {
      final initialStr = widget.initialCategory!.toLowerCase().trim();
      
      if (initialStr.contains('deal') || initialStr.contains('sale') || initialStr.contains('promo')) {
        _selectedCategoryIndex = 1; // Deals & Promotions
        _onlyOnSale = true;
      } else if (initialStr.contains('rice') || initialStr.contains('chawal')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('rice'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('flour') || initialStr.contains('floor') || initialStr.contains('atta') || initialStr.contains('maida')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('flour'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('daal') || initialStr.contains('pulse') || initialStr.contains('lentil')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('daal') || (c['name'] as String).toLowerCase().contains('pulse'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('cheese')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('cheese'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('beverage') || initialStr.contains('drink')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('beverage'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('pack')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('pack'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('sauce') || initialStr.contains('condiment')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('sauce'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('clean')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('clean'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('canned')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('canned'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('kitchen')) {
        final kitchenIdx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('kitchen'));
        _selectedCategoryIndex = kitchenIdx != -1 ? kitchenIdx : 0;
      } else if (initialStr.contains('oil')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('oil'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('tea')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('tea'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('coffee')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('coffee'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('tissue') || initialStr.contains('hygiene')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('tissue') || (c['name'] as String).toLowerCase().contains('hygiene'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else if (initialStr.contains('dispos')) {
        final idx = _categories.indexWhere((c) => (c['name'] as String).toLowerCase().contains('dispos'));
        _selectedCategoryIndex = idx != -1 ? idx : 0;
      } else {
        final cleanInitial = initialStr
            .replaceAll('essentials', '')
            .replaceAll('supplies', '')
            .replaceAll('materials', '')
            .replaceAll('goods', '')
            .replaceAll('products', '')
            .replaceAll('& condiments', '')
            .replaceAll('& drinks', '')
            .replaceAll('& soft drinks', '')
            .replaceAll('& hygiene', '')
            .replaceAll('boxes', '')
            .trim();

        final idx = _categories.indexWhere((c) {
          final target = (c['target'] as String?)?.toLowerCase() ?? '';
          final name = (c['name'] as String).toLowerCase();
          return target == initialStr || name.contains(initialStr) || initialStr.contains(name) ||
                 (cleanInitial.isNotEmpty && (name.contains(cleanInitial) || target.contains(cleanInitial))) ||
                 name.replaceAll('s', '') == initialStr.replaceAll('s', '');
        });
        
        if (idx != -1) {
          _selectedCategoryIndex = idx;
        } else {
          _categories.add({
            'id': 0,
            'name': widget.initialCategory!,
            'target': widget.initialCategory!,
          });
          _selectedCategoryIndex = _categories.length - 1;
        }
      }
    }

    // 3. Fetch products
    _currentTitle = widget.pageTitle;
    if (_selectedCategoryIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_categoryScrollController.hasClients) {
          final targetOffset = (_selectedCategoryIndex * 100.0 - 40.0).clamp(0.0, _categoryScrollController.position.maxScrollExtent);
          _categoryScrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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

    final currentCategory = _categories.isNotEmpty && _selectedCategoryIndex < _categories.length
        ? _categories[_selectedCategoryIndex]
        : {'id': 0, 'name': 'All Products', 'target': null};
    final rawCatId = currentCategory['id'];
    final targetKeyword = currentCategory['target'] as String?;

    try {
      String? finalSearchQuery = _searchQuery.isEmpty ? null : _searchQuery;
      
      // If Deals & Promotions tab is selected (id == -1), search all products on sale
      final isDeals = rawCatId == -1 || rawCatId == '-1';
      final effectiveCategoryId = (rawCatId == null || rawCatId == 0 || rawCatId == '0' || isDeals) 
          ? null 
          : rawCatId.toString();
      final effectiveOnSale = isDeals ? true : (_onlyOnSale ? true : null);

      // If we are on a category tab that has no WooCommerce ID (and not deals), we use its target keyword as search query
      if (effectiveCategoryId == null && !isDeals && targetKeyword != null && _searchQuery.isEmpty) {
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
        perPage: finalSearchQuery != null ? 100 : 20,
        categoryId: effectiveCategoryId,
        onSale: effectiveOnSale,
        searchQuery: finalSearchQuery,
        orderBy: orderBy,
        order: order,
      );

      if (_onlyOnSale && newProducts.isNotEmpty) {
        newProducts.retainWhere((product) {
          final regularPrice = double.tryParse(product['regular_price']?.toString() ?? '0') ?? 0.0;
          final salePrice = double.tryParse(product['sale_price']?.toString() ?? '0') ?? 0.0;
          final actualPrice = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
          return product['on_sale'] == true || (salePrice > 0 && salePrice < regularPrice) || (regularPrice > actualPrice);
        });
      }

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
      
      if (_products.isEmpty) {
        if (rawCatId == 366 || rawCatId == '366' || (targetKeyword != null && targetKeyword.toLowerCase().contains('rice'))) {
          _products.addAll([
            {
              'id': '30517',
              'name': 'Steam Rice (سٹیم رائس) - 1kg',
              'price': '360',
              'regular_price': '390',
              'sale_price': '360',
              'on_sale': false,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/Rice.png'}],
            },
            {
              'id': '30514',
              'name': 'Sella Rice (سیللا چاول) - 1kg',
              'price': '340',
              'regular_price': '370',
              'sale_price': '340',
              'on_sale': false,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/Rice.png'}],
            },
          ]);
        } else if (rawCatId == 365 || rawCatId == '365' || (targetKeyword != null && targetKeyword.toLowerCase().contains('flour'))) {
          _products.addAll([
            {
              'id': '30509',
              'name': 'Corn Flour (مکئی کا آٹا) - 1kg',
              'price': '280',
              'regular_price': '310',
              'sale_price': '280',
              'on_sale': false,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/Flour.png'}],
            },
            {
              'id': '30505',
              'name': 'Maida (میدہ) - 1kg',
              'price': '190',
              'regular_price': '220',
              'sale_price': '190',
              'on_sale': false,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/Flour.png'}],
            },
          ]);
        } else {
          _products.addAll([
            {
              'id': '1001',
              'name': 'Mozzarella Cheese Shredded 2kg',
              'price': '2850',
              'regular_price': '3200',
              'sale_price': '2850',
              'on_sale': true,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png'}],
            },
            {
              'id': '1002',
              'name': 'Pure Cooking Oil 5L Can',
              'price': '2450',
              'regular_price': '2700',
              'sale_price': '2450',
              'on_sale': true,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/03_Cooking_Oils.png'}],
            },
            {
              'id': '1003',
              'name': 'Special Garam Masala Pack 1kg',
              'price': '850',
              'regular_price': '1000',
              'sale_price': '850',
              'on_sale': true,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/07_Spices.png'}],
            },
            {
              'id': '1004',
              'name': 'Tomato Ketchup 5kg Commercial Jar',
              'price': '1250',
              'regular_price': '1400',
              'sale_price': '1250',
              'on_sale': true,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/Sauces.png'}],
            },
            {
              'id': '1005',
              'name': 'Paper Food Box 500 Pcs Pack',
              'price': '1850',
              'regular_price': '2100',
              'sale_price': '1850',
              'on_sale': false,
              'images': [{'src': 'assets/images/RestoMart_All_Category_Images_430x430/05_Packaging_Materials.png'}],
            },
          ]);
        }
      }
      
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
      final cat = _categories[index];
      _currentTitle = cat['name'] as String?;
      if (cat['id'] == -1 || cat['target'] == 'deals') {
        _onlyOnSale = true;
      } else {
        _onlyOnSale = false;
      }
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
    _categoryScrollController.dispose();
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
                  _currentTitle ?? (_onlyOnSale 
                    ? 'Deals & Discounts' 
                    : (_categories.isNotEmpty ? _categories[_selectedCategoryIndex]['name'] : 'All Products')), 
                  style: const TextStyle(
                    color: Color(0xFF25258F),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _onlyOnSale 
                    ? 'Exclusive discounted items & special bulk offers' 
                    : 'Browse premium items for your restaurant',
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
            child: GestureDetector(
              onTap: () {
                Get.to(() => SearchView(initialQuery: _searchQuery));
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
                    Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _searchQuery.isNotEmpty ? _searchQuery : 'Search for products and categories...',
                        style: TextStyle(
                          color: _searchQuery.isNotEmpty ? const Color(0xFF20283A) : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          _fetchProducts(loadMore: false);
                        },
                        child: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      ),
                  ],
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
                controller: _categoryScrollController,
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
                            color: isSelected ? AppColors.primary : Colors.transparent,
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
                            color: isSelected ? AppColors.primary : Colors.grey.shade600,
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
