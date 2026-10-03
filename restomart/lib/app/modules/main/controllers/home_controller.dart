import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/woocommerce_api_service.dart';

class WooCommerceProduct {
  final int id;
  final String name;
  final String image;
  final int price;
  final int? originalPrice;
  final bool isOnSale;
  final String category;

  WooCommerceProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.isOnSale,
    required this.category,
  });

  factory WooCommerceProduct.fromJson(Map<String, dynamic> json) {
    String img = '';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      img = json['images'][0]['src'] ?? img;
    }

    int currentPrice = 0;
    int? oldPrice;
    
    currentPrice = (double.tryParse(json['price']?.toString() ?? '0') ?? 0).round();
    
    if (json['regular_price'] != null && json['regular_price'].toString().isNotEmpty) {
      int reg = (double.tryParse(json['regular_price'].toString()) ?? 0).round();
      if (reg > currentPrice) {
        oldPrice = reg;
      }
    }

    String cat = 'Grocery';
    if (json['categories'] != null && (json['categories'] as List).isNotEmpty) {
      cat = json['categories'][0]['name'] ?? cat;
    }

    return WooCommerceProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: img,
      price: currentPrice,
      originalPrice: oldPrice,
      isOnSale: json['on_sale'] ?? false,
      category: cat,
    );
  }
}

class HomeController extends GetxController {
  final isLoading = true.obs;
  
  final allProducts = <WooCommerceProduct>[].obs;
  
  // Specific sections
  final categories = <Map<String, dynamic>>[].obs;
  final cheeseEssentials = <WooCommerceProduct>[].obs;
  final salePicks = <WooCommerceProduct>[].obs;
  final recentlyViewed = <WooCommerceProduct>[].obs;
  final packagingEssentials = <WooCommerceProduct>[].obs;
  final pickedForKitchen = <WooCommerceProduct>[].obs;
  final beveragesList = <WooCommerceProduct>[].obs;
  final saucesList = <WooCommerceProduct>[].obs;
  final cleaningList = <WooCommerceProduct>[].obs;
  final cannedList = <WooCommerceProduct>[].obs;

  void addToRecentlyViewed(WooCommerceProduct product) {
    recentlyViewed.removeWhere((p) => p.id == product.id);
    recentlyViewed.insert(0, product);
    if (recentlyViewed.length > 10) {
      recentlyViewed.removeLast();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      
      // 1. Fetch Categories
      final catsData = await WooCommerceApiService.getCategories();
      final List<Map<String, dynamic>> processedCats = [];
      for (var cat in catsData) {
        if (cat is Map<String, dynamic>) {
          String name = (cat['name']?.toString() ?? '').toLowerCase();
          var imageObj = cat['image'];
          
          if (imageObj == null || (imageObj is Map && (imageObj['src'] == null || imageObj['src'].toString().isEmpty))) {
            // Provide exact mappings using the new 430x430 images
            String fallback = '';
            String prefix = 'assets/images/RestoMart_All_Category_Images_430x430/';

            if (name.contains('bake') || name.contains('flour') || name.contains('bread')) fallback = '${prefix}10_Baking_Products.png';
            else if (name.contains('beauty') || name.contains('anua') || name.contains('tirtir') || name.contains('makeup') || name.contains('cosmetic')) fallback = '${prefix}13_Beauty_Products.png';
            else if (name.contains('can')) fallback = '${prefix}11_Canned_Products.png';
            else if (name.contains('clean') || name.contains('trash') || name.contains('surf') || name.contains('soap')) fallback = '${prefix}09_Cleaning_Products.png';
            else if (name.contains('oil')) fallback = '${prefix}03_Cooking_Oils.png';
            else if (name.contains('cheese')) fallback = '${prefix}01_Cheese.png';
            else if (name.contains('milk') || name.contains('dairy')) fallback = '${prefix}04_Milks.png';
            else if (name.contains('dry fruit') || name.contains('nut')) fallback = '${prefix}08_Dry_Fruits.png';
            else if (name.contains('pack')) fallback = '${prefix}05_Packaging_Materials.png';
            else if (name.contains('spice') || name.contains('masala')) fallback = '${prefix}07_Spices.png';
            else if (name.contains('station')) fallback = '${prefix}12_Stationery.png';
            else if (name.contains('tea')) fallback = '${prefix}06_Tea.png';
            else if (name.contains('coffee')) fallback = '${prefix}Coffee.png';
            else if (name.contains('drink') || name.contains('beverage') || name.contains('juice') || name.contains('water') || name.contains('sharbat')) fallback = '${prefix}02_Beverages.png';
            else if (name.contains('kitchen') || name.contains('access') || name.contains('pot') || name.contains('pan')) fallback = '${prefix}Kitchen_Accessories.png';
            else if (name.contains('sauce') || name.contains('ketchup') || name.contains('mayo')) fallback = '${prefix}Sauces.png';
            else if (name.contains('dispos') || name.contains('paper') || name.contains('cup')) fallback = '${prefix}Disposables.png';
            else if (name.contains('choco')) fallback = '${prefix}Chocolates.png';
            else if (name.contains('sweet') || name.contains('candy') || name.contains('jelly')) fallback = '${prefix}Sweets.png';
            else if (name.contains('tissue') || name.contains('hygiene') || name.contains('wipe')) fallback = '${prefix}Tissues_and_Hygiene.png';
            else if (name.contains('fragrance') || name.contains('scent') || name.contains('perfume')) fallback = '${prefix}Fragrances.png';
            else if (name.contains('footwear') || name.contains('shoe') || name.contains('sandal') || name.contains('slipper')) fallback = '${prefix}Footwear.png';
            else fallback = 'assets/images/logo.png'; // default fallback for unmapped
            
            cat['image'] = {'src': fallback};
          }
          processedCats.add(cat);
        }
      }
      // Sort to prioritize B2B restaurant essentials
      processedCats.sort((a, b) {
        String nameA = (a['name']?.toString() ?? '').toLowerCase();
        String nameB = (b['name']?.toString() ?? '').toLowerCase();
        
        // Define a strict ordering of important keywords for restaurants
        List<String> priorityOrder = [
          'oil', 'spice', 'masala', 'cheese', 'chicken', 'meat', 'dairy', 'milk', 
          'rice', 'flour', 'baking', 'packaging', 'box', 'sauce', 'canned', 'cleaning',
          'beverage', 'drink', 'water', 'tea', 'coffee'
        ];
        
        // Minor items we explicitly want at the bottom
        List<String> bottomOrder = [
          'chocolate', 'candy', 'sweet', 'jelly', 'beauty', 'skincare', 'makeup', 'footwear', 'shoe', 'anua', 'tirtir'
        ];

        int getPriority(String name) {
          // Check for bottom-tier items
          for (int i = 0; i < bottomOrder.length; i++) {
            if (name.contains(bottomOrder[i])) {
              return 1000 + i; // Very low priority
            }
          }
          // Check for top-tier items
          for (int i = 0; i < priorityOrder.length; i++) {
            if (name.contains(priorityOrder[i])) {
              return i;
            }
          }
          return 500; // Middle priority for anything else
        }

        int priorityA = getPriority(nameA);
        int priorityB = getPriority(nameB);

        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        return nameA.compareTo(nameB);
      });
      
      categories.value = processedCats;

      // 2. Fetch Products
      final prodsData = await WooCommerceApiService.getProducts(perPage: 100);
      final List<WooCommerceProduct> products = [];
      for (var item in prodsData) {
        products.add(WooCommerceProduct.fromJson(item));
      }
      
      allProducts.value = products;
      
      // Distribute products into sections based on real data
      cheeseEssentials.value = products.where((p) => p.name.toLowerCase().contains('cheese') || p.category.toLowerCase().contains('cheese') || p.category.toLowerCase().contains('dairy')).take(4).toList();
      
      salePicks.value = products.where((p) => p.isOnSale).take(4).toList();
      if (salePicks.isEmpty && products.isNotEmpty) {
        // Fallback to top Kitchen Accessories if no items are on sale
        salePicks.value = products.where((p) => p.category.toLowerCase().contains('kitchen')).take(4).toList();
      }

      packagingEssentials.value = products.where((p) => p.category.toLowerCase().contains('pack')).take(4).toList();
      
      pickedForKitchen.value = products.where((p) => p.category.toLowerCase().contains('kitchen') || p.name.toLowerCase().contains('oil') || p.name.toLowerCase().contains('spice') || p.category.toLowerCase().contains('masala')).take(4).toList();
      
      beveragesList.value = products.where((p) => p.category.toLowerCase().contains('beverage') || p.category.toLowerCase().contains('drink') || p.category.toLowerCase().contains('coffee') || p.category.toLowerCase().contains('tea')).take(4).toList();

      saucesList.value = products.where((p) => p.category.toLowerCase().contains('sauce') || p.name.toLowerCase().contains('ketchup') || p.name.toLowerCase().contains('mayo')).take(4).toList();

      cleaningList.value = products.where((p) => p.category.toLowerCase().contains('cleaning') || p.category.toLowerCase().contains('hygiene') || p.name.toLowerCase().contains('surf')).take(4).toList();

      cannedList.value = products.where((p) => p.category.toLowerCase().contains('canned') || p.name.toLowerCase().contains('corn') || p.name.toLowerCase().contains('olive')).take(4).toList();
      
    } catch (e) {
      print("Error loading products: $e");
      Get.snackbar(
        'Network Error', 
        'Could not load products. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEBEE),
        colorText: const Color(0xFFC62828),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
