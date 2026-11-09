import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../widgets/product_card.dart';
import '../../cart/controllers/cart_controller.dart';
import 'all_products_view.dart';

class SearchView extends StatefulWidget {
  final String? initialQuery;
  const SearchView({super.key, this.initialQuery});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<String> _recentSearches = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  final List<Map<String, String>> _popularCategories = [
    {'title': 'Cheese', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png'},
    {'title': 'Cooking Oils', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/03_Cooking_Oils.png'},
    {'title': 'Milks', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/04_Milks.png'},
    {'title': 'Beverages', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/02_Beverages.png'},
    {'title': 'Packaging', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/05_Packaging_Materials.png'},
    {'title': 'Spices', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/07_Spices.png'},
    {'title': 'Bakery', 'image': 'assets/images/RestoMart_All_Category_Images_430x430/10_Baking_Products.png'},
  ];

  final List<String> _popularSearches = [
    'mezan oil',
    'adams cheese',
    'milk',
    'lipton tea',
    'sufi oil',
    'garam masala',
    'packaging box',
    'sauce',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getStringList('recent_searches_list') ?? [
      'mezan oil',
      'cheese slices',
      'milk 1L',
      'tea bags',
    ];
    setState(() {
      _recentSearches = loaded;
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _recentSearches.removeWhere((item) => item.toLowerCase() == q.toLowerCase());
    _recentSearches.insert(0, q);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches_list', _recentSearches);
    setState(() {});
  }

  Future<void> _removeRecentSearch(int index) async {
    if (index >= 0 && index < _recentSearches.length) {
      _recentSearches.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches_list', _recentSearches);
      setState(() {});
    }
  }

  Future<void> _clearAllRecentSearches() async {
    _recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches_list');
    setState(() {});
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    _saveRecentSearch(cleanQuery);

    try {
      final q = cleanQuery.toLowerCase();
      final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

      // Check if query matches known primary category
      String? categoryId;
      if (q.contains('milk') || q.contains('dairy')) {
        categoryId = '60'; // Dairy Milk category
      } else if (q.contains('cheese')) {
        categoryId = '354';
      } else if (q.contains('rice') || q.contains('chawal')) {
        categoryId = '366';
      } else if (q.contains('flour') || q.contains('floor') || q.contains('atta') || q.contains('maida')) {
        categoryId = '365';
      } else if (q.contains('oil') || q.contains('ghee')) {
        categoryId = '355';
      } else if (q.contains('daal') || q.contains('pulse') || q.contains('lentil')) {
        categoryId = '367';
      } else if (q.contains('tea')) {
        categoryId = '59';
      } else if (q.contains('coffee')) {
        categoryId = '337';
      } else if (q.contains('beverage') || q.contains('drink') || q.contains('juice') || q.contains('soda')) {
        categoryId = '18,604,223,349,337,59';
      } else if (q.contains('sauce') || q.contains('ketchup') || q.contains('mayo')) {
        categoryId = '23,30,224';
      } else if (q.contains('canned') || q.contains('can')) {
        categoryId = '20,1220';
      } else if (q.contains('clean') || q.contains('soap') || q.contains('surf')) {
        categoryId = '52,34,345,347,603,348';
      } else if (q.contains('pack') || q.contains('box')) {
        categoryId = '50,220,330';
      }

      // Fetch products in parallel: text search (100 per page) + category products (if applicable)
      final List<Future<List<dynamic>>> futures = [
        WooCommerceApiService.getProducts(
          page: 1,
          perPage: 100,
          searchQuery: cleanQuery,
        ),
      ];

      if (categoryId != null) {
        futures.add(
          WooCommerceApiService.getProducts(
            page: 1,
            perPage: 50,
            categoryId: categoryId,
          ),
        );
      }

      final responses = await Future.wait(futures);
      final Map<String, dynamic> uniqueMap = {};
      for (final list in responses) {
        for (final item in list) {
          final id = item['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            uniqueMap[id] = item;
          }
        }
      }
      final allResults = uniqueMap.values.toList();

      // Filter: MAIN FOCUS IN TITLE (Ignore ingredients/description-only matches)
      final List<dynamic> titleMatches = [];
      final List<dynamic> otherMatches = [];

      for (final product in allResults) {
        final name = (product['name']?.toString() ?? '').toLowerCase();
        final titleTokens = name.split(RegExp(r'[\s\-_,.()/+]+')).where((w) => w.isNotEmpty).toList();

        // Check if query or search words appear in title
        bool isTitleMatch = false;
        if (name.contains(q)) {
          isTitleMatch = true;
        } else if (words.length > 1) {
          isTitleMatch = words.every((w) => titleTokens.any((t) => t.contains(w) || w.contains(t)));
        } else if (words.isNotEmpty) {
          final singleWord = words.first;
          isTitleMatch = titleTokens.any((t) => t.startsWith(singleWord) || singleWord.startsWith(t) || t.contains(singleWord));
        }

        // Also include items with matching primary category if not cosmetic
        final cats = (product['categories'] as List?) ?? [];
        final hasCatMatch = cats.any((c) {
          final cName = (c is Map ? (c['name']?.toString() ?? '') : c.toString()).toLowerCase();
          return words.any((w) => cName.contains(w));
        });

        if (isTitleMatch || (hasCatMatch && !name.contains('makeup') && !name.contains('cosmetic'))) {
          titleMatches.add(product);
        } else {
          otherMatches.add(product);
        }
      }

      // Smart Ranking of Title Matches
      titleMatches.sort((a, b) {
        final aName = (a['name']?.toString() ?? '').toLowerCase();
        final bName = (b['name']?.toString() ?? '').toLowerCase();
        final aCats = ((a['categories'] as List?) ?? []).map((c) => (c is Map ? (c['name']?.toString() ?? '') : c.toString()).toLowerCase()).toList();
        final bCats = ((b['categories'] as List?) ?? []).map((c) => (c is Map ? (c['name']?.toString() ?? '') : c.toString()).toLowerCase()).toList();

        final aIsCosmetic = aCats.any((c) => c.contains('makeup') || c.contains('beauty') || c.contains('anua'));
        final bIsCosmetic = bCats.any((c) => c.contains('makeup') || c.contains('beauty') || c.contains('anua'));

        if (aIsCosmetic && !bIsCosmetic) return 1;
        if (!aIsCosmetic && bIsCosmetic) return -1;

        int score(dynamic p, String name, List<String> cats) {
          int s = 0;
          final tokens = name.split(RegExp(r'[\s\-_,.()/+]+')).where((w) => w.isNotEmpty).toList();
          
          // Standalone exact token match in title (e.g. "milk" in "Nestle Milk Pak")
          if (tokens.any((t) => words.contains(t))) s += 500;
          
          // Name starts with query
          if (name.startsWith(q)) s += 300;
          
          // Full query in title
          if (name.contains(q)) s += 200;
          
          // Category match
          if (cats.any((c) => words.any((w) => c.contains(w)))) s += 150;
          
          // Direct, shorter names prioritized
          s += (100 - name.length).clamp(0, 100);
          return s;
        }

        return score(b, bName, bCats).compareTo(score(a, aName, aCats));
      });

      setState(() {
        // Main focus in title: Ignore ingredient/description matches when title matches exist!
        _searchResults = titleMatches.isNotEmpty ? titleMatches : otherMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectSearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: term.length));
    _performSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    final queryText = _searchController.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 16),
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FB),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search for products and categories...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF25258F), size: 20),
              suffixIcon: queryText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: queryText.isNotEmpty
          ? _buildLiveResultsView()
          : _buildDefaultSuggestionsView(),
    );
  }

  Widget _buildDefaultSuggestionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Browse Full Catalog Banner ──
          InkWell(
            onTap: () {
              Get.to(() => const AllProductsView(pageTitle: 'All Products Catalog'));
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA000), Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Browse Full Products Catalog',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── 1. Popular Categories ──
          const Text(
            'Popular Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popularCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final cat = _popularCategories[index];
                return GestureDetector(
                  onTap: () {
                    Get.to(() => AllProductsView(
                      initialCategory: cat['title'],
                      pageTitle: cat['title'],
                    ));
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          cat['image']!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, color: Color(0xFF25258F)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['title']!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── 2. Recent Searches ──
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                TextButton(
                  onPressed: _clearAllRecentSearches,
                  child: const Text('Clear All', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(_recentSearches.length, (index) {
                final term = _recentSearches[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, color: Colors.grey, size: 20),
                  title: Text(
                    term,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                    onPressed: () => _removeRecentSearch(index),
                  ),
                  onTap: () => _selectSearchTerm(term),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],

          // ── 3. Popular Searches (Chips) ──
          const Text(
            'Popular Searches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularSearches.map((term) {
              return InkWell(
                onTap: () => _selectSearchTerm(term),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    term,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF25258F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLiveResultsView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF25258F)),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No products found for "${_searchController.text.trim()}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: _searchResults.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final p = _searchResults[index];
          final String id = (p['id'] ?? index).toString();
          final String name = p['name'] ?? 'RestoMart Item';
          final double price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;
          final double regularPrice = double.tryParse(p['regular_price']?.toString() ?? '0') ?? price;
          final String imagePath = (p['images'] != null && p['images'].isNotEmpty)
              ? p['images'][0]['src'] ?? ''
              : '';

          final int discount = (regularPrice > price && regularPrice > 0)
              ? (((regularPrice - price) / regularPrice) * 100).round()
              : 0;

          return ProductCard(
            id: id,
            name: name,
            salePrice: price,
            originalPrice: regularPrice > price ? regularPrice : price,
            discountPercent: discount,
            imagePath: imagePath,
            onAddToCart: () {
              final cart = Get.find<CartController>();
              cart.addToCart(id, imagePath, name, price, 1, originalPrice: regularPrice);
            },
          );
        },
      ),
    );
  }
}
