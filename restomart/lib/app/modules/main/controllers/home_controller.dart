import 'dart:developer';
import 'package:get/get.dart';
import '../../../core/services/woocommerce_api_service.dart';
import '../../../core/utils/error_handler.dart';

class WooCommerceProduct {
  final int id;
  final String name;
  final String image;
  final int price;
  final int? originalPrice;
  final bool isOnSale;
  final String category;
  final List<String> categories;
  final List<int> categoryIds;

  WooCommerceProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.isOnSale,
    required this.category,
    this.categories = const [],
    this.categoryIds = const [],
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

    List<String> cats = [];
    List<int> catIds = [];
    if (json['categories'] != null && (json['categories'] as List).isNotEmpty) {
      for (var c in json['categories']) {
        if (c is Map) {
          if (c['name'] != null) cats.add(c['name'].toString().trim());
          if (c['id'] != null) {
            final cid = int.tryParse(c['id'].toString());
            if (cid != null) catIds.add(cid);
          }
        }
      }
    }

    // Select the most specific category name (not generic 'Grocery')
    String cat = 'Grocery';
    for (var cName in cats) {
      if (cName.toLowerCase() != 'grocery') {
        cat = cName;
        break;
      }
    }
    if (cat == 'Grocery' && cats.isNotEmpty) {
      cat = cats.first;
    }

    return WooCommerceProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: img,
      price: currentPrice,
      originalPrice: oldPrice,
      isOnSale: json['on_sale'] ?? false,
      category: cat,
      categories: cats,
      categoryIds: catIds,
    );
  }
}

class HomeController extends GetxController {
  final isLoading = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isNetworkError = false.obs;
  
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
      hasError.value = false;
      errorMessage.value = '';
      isNetworkError.value = false;
      
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

            if (name.contains('flour') || name.contains('floor') || name.contains('atta') || name.contains('maida')) {
              fallback = '${prefix}Flour.png';
            } else if (name.contains('rice') || name.contains('chawal')) {
              fallback = '${prefix}Rice.png';
            } else if (name.contains('daal') || name.contains('pulse') || name.contains('lentil')) {
              fallback = '${prefix}08_Dry_Fruits.png';
            } else if (name.contains('bake') || name.contains('bread')) {
              fallback = '${prefix}10_Baking_Products.png';
            }
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

        int getPriority(Map<String, dynamic> cat) {
          final String name = (cat['name']?.toString() ?? '').toLowerCase();
          final int id = int.tryParse(cat['id']?.toString() ?? '') ?? 0;
          final int parent = int.tryParse(cat['parent']?.toString() ?? '') ?? 0;

          // Demote makeup / cosmetic items (like MILK toner/makeup id 1043 or parent 1011)
          if (id == 1043 || parent == 1011) {
            return 1500;
          }
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

        int priorityA = getPriority(a);
        int priorityB = getPriority(b);

        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        String nameA = (a['name']?.toString() ?? '').toLowerCase();
        String nameB = (b['name']?.toString() ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });
      
      categories.value = processedCats;

      // 2. Fetch Products in Parallel (General Feed + Dedicated Category Feeds)
      final results = await Future.wait([
        WooCommerceApiService.getProducts(perPage: 30), // 0: general & sale products
        WooCommerceApiService.getProducts(categoryId: '18,604,223,349,337,59', perPage: 8), // 1: Beverages & Drinks
        WooCommerceApiService.getProducts(categoryId: '50,220,330', perPage: 8), // 2: Packaging & Disposables
        WooCommerceApiService.getProducts(categoryId: '52,34,345,347,603,348', perPage: 8), // 3: Cleaning & Hygiene
        WooCommerceApiService.getProducts(categoryId: '23,30,224', perPage: 8), // 4: Sauces & Condiments
        WooCommerceApiService.getProducts(categoryId: '354', perPage: 8), // 5: Pure Cheese
        WooCommerceApiService.getProducts(categoryId: '20,1220', perPage: 8), // 6: Canned Products
      ]);

      final List<WooCommerceProduct> products = [];
      for (var item in results[0]) {
        products.add(WooCommerceProduct.fromJson(item));
      }
      if (products.isEmpty) {
        products.addAll(_getOfflineFallbackProducts());
      }
      allProducts.value = products;

      final curatedBusinessDeals = [
        WooCommerceProduct(
          id: 38214,
          name: 'Restomart Special Frozen Food Deal – Seekh Kebab, Kofta, Burger Patty & Nuggets',
          price: 1899,
          originalPrice: 2299,
          isOnSale: true,
          image: 'assets/images/RestoMart-Frozen-Food-Deal-Offer-430x430.png',
          category: 'Special Frozen Deal',
        ),
        WooCommerceProduct(
          id: 9903,
          name: 'Mezan Perfect Frying Oil 16 Ltr Tin',
          price: 7490,
          originalPrice: 8990,
          isOnSale: true,
          image: 'assets/images/B2B-SKU-Mezan-Perfect-Frying-Oil-Tin-16-Ltr-430x430.webp',
          category: 'Weekly Oil Saver',
        ),
        WooCommerceProduct(
          id: 9904,
          name: 'Adams White Cheese Slices 1kg Pack',
          price: 1290,
          originalPrice: 1550,
          isOnSale: true,
          image: 'assets/images/Adams-Cheese-Slice-White-1kg-430x430.webp',
          category: 'Commercial Dairy',
        ),
        WooCommerceProduct(
          id: 9902,
          name: 'RestoMart Special Frozen Food Mega Saver Pack',
          price: 2850,
          originalPrice: 3500,
          isOnSale: true,
          image: 'assets/images/RestoMart-Frozen-Food-Deal-Offer-430x430.png',
          category: 'Frozen Foods Deal',
        ),
      ];

      final onSaleProducts = products.where((p) => p.isOnSale && p.id != 38214 && !curatedBusinessDeals.any((c) => c.id == p.id)).toList();
      salePicks.value = [
        ...curatedBusinessDeals,
        ...onSaleProducts,
      ];

      // 1. Dedicated Beverages Feed (no parathas or random sweets)
      final rawBevs = results[1]
          .map((i) => WooCommerceProduct.fromJson(i))
          .where((p) => !p.name.toLowerCase().contains('paratha') && !p.name.toLowerCase().contains('roti'))
          .toList();
      beveragesList.value = rawBevs.isNotEmpty ? rawBevs : _getFallbackBeverages();

      // 2. Dedicated Packaging Feed (real takeaway boxes, gloves, containers)
      final rawPack = results[2].map((i) => WooCommerceProduct.fromJson(i)).toList();
      packagingEssentials.value = rawPack.isNotEmpty ? rawPack : _getFallbackPackaging();

      // 3. Dedicated Cleaning & Hygiene Feed (real detergents, air fresheners, soaps)
      final rawClean = results[3]
          .map((i) => WooCommerceProduct.fromJson(i))
          .where((p) => !p.name.toLowerCase().contains('essence') && !p.name.toLowerCase().contains('flavor'))
          .toList();
      cleaningList.value = rawClean.isNotEmpty ? rawClean : _getFallbackCleaning();

      // 4. Dedicated Sauces Feed (peri-peri, ketchups, mayo)
      final rawSauces = results[4].map((i) => WooCommerceProduct.fromJson(i)).toList();
      saucesList.value = rawSauces.isNotEmpty ? rawSauces : _getFallbackSauces();

      // 5. Dedicated Pure Cheese Feed (Adams, Mozzarella, Cheddar)
      final rawCheese = results[5].map((i) => WooCommerceProduct.fromJson(i)).toList();
      cheeseEssentials.value = rawCheese.isNotEmpty ? rawCheese : _getFallbackCheese();

      // 6. Dedicated Canned Goods Feed (mushrooms, beans, jalapenos)
      final rawCanned = results[6].map((i) => WooCommerceProduct.fromJson(i)).toList();
      cannedList.value = rawCanned.isNotEmpty ? rawCanned : _getFallbackCanned();
      
    } catch (e) {
      log("Error loading products: $e");
      hasError.value = true;
      if (AppErrorHandler.isNetworkError(e)) {
        isNetworkError.value = true;
        errorMessage.value = 'No internet connection. Showing saved products.';
        AppErrorHandler.showOfflineError();
      } else {
        errorMessage.value = AppErrorHandler.getErrorMessage(e);
      }
      if (allProducts.isEmpty) {
        final fallback = _getOfflineFallbackProducts();
        allProducts.value = fallback;
        salePicks.value = fallback.take(4).toList();
        cheeseEssentials.value = _getFallbackCheese();
        beveragesList.value = _getFallbackBeverages();
        packagingEssentials.value = _getFallbackPackaging();
        cleaningList.value = _getFallbackCleaning();
        saucesList.value = _getFallbackSauces();
        cannedList.value = _getFallbackCanned();
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<WooCommerceProduct> _getFallbackBeverages() {
    return [
      WooCommerceProduct(
        id: 33856,
        name: 'Next Cola Soft Drink 1.5 L Pet',
        price: 180,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/03/Next-Cola-1.5L.png',
        category: 'Cold Drink',
      ),
      WooCommerceProduct(
        id: 34947,
        name: 'Torabika Cappuccino Sachet',
        price: 90,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/08/Torabika-Cappuccino.webp',
        category: 'Beverage',
      ),
      WooCommerceProduct(
        id: 34877,
        name: 'Bonmano 3x1 Coffee Mix Classic Sachet',
        price: 90,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/07/Bonmano-3x1-Coffee-Mix-Classic.jpg',
        category: 'Coffee',
      ),
      WooCommerceProduct(
        id: 34888,
        name: 'Bonmano Hot Chocolate Smooth & Creamy Sachet',
        price: 90,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/07/Bonmano-Hot-Chocolate.webp',
        category: 'Beverage',
      ),
    ];
  }

  List<WooCommerceProduct> _getFallbackPackaging() {
    return [
      WooCommerceProduct(
        id: 30501,
        name: 'Thermocol Boxes LP 15 | Pack of 24',
        price: 168,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2024/10/images-1.jpeg',
        category: 'Packaging',
      ),
      WooCommerceProduct(
        id: 30497,
        name: 'Thermocol Food Boxes LP 14 | Pack of 24',
        price: 120,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2024/10/images-1.jpeg',
        category: 'Packaging',
      ),
      WooCommerceProduct(
        id: 33486,
        name: 'Medicare Disposable Vinyl Gloves 100pcs',
        price: 1550,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/03/Untitled-design-5-1.png',
        category: 'Disposable',
      ),
      WooCommerceProduct(
        id: 1006,
        name: 'Paper Food Box 500 Pcs Pack',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/05_Packaging_Materials.png',
        price: 1850,
        originalPrice: 2100,
        isOnSale: false,
        category: 'Packaging',
      ),
    ];
  }

  List<WooCommerceProduct> _getFallbackCleaning() {
    return [
      WooCommerceProduct(
        id: 34065,
        name: 'Sufii Detergent Soap Special 1Kg',
        price: 600,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/04/Sufii-Detergent-Soap-Special-1kg.png',
        category: 'Cleaning',
      ),
      WooCommerceProduct(
        id: 33996,
        name: 'Fresco 212 VIP Air Freshener 300ml',
        price: 500,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/04/Fresco-212-VIP-Air-Freshener-300ml-.png',
        category: 'Cleaning',
      ),
      WooCommerceProduct(
        id: 33985,
        name: 'Fresco Cool Water Air Freshener 300ml',
        price: 480,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/04/Fresco-Cool-Water-Air-Freshener-300ml.png',
        category: 'Cleaning',
      ),
      WooCommerceProduct(
        id: 34071,
        name: 'White Petal Luxury Tissues with 200 sheets (100x2ply)',
        price: 180,
        isOnSale: false,
        image: 'https://restomart.pk/wp-content/uploads/2025/04/White-Petal-Luxury-Tissues-with-200-sheets-100x2ply.png',
        category: 'Cleaning',
      ),
    ];
  }

  List<WooCommerceProduct> _getFallbackCheese() {
    return [
      WooCommerceProduct(
        id: 9904,
        name: "Adam's Cheese Slice White - 1kg",
        price: 1290,
        originalPrice: 1550,
        isOnSale: true,
        image: 'assets/images/Adams-Cheese-Slice-White-1kg-430x430.webp',
        category: 'Cheese',
      ),
      WooCommerceProduct(
        id: 1001,
        name: 'Adams Mozzarella Cheese Block - 2kg',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png',
        price: 2850,
        originalPrice: 3200,
        isOnSale: true,
        category: 'Cheese',
      ),
      WooCommerceProduct(
        id: 1002,
        name: 'Cheddar Cheese Block 1kg',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png',
        price: 1950,
        originalPrice: 2200,
        isOnSale: true,
        category: 'Cheese',
      ),
      WooCommerceProduct(
        id: 1007,
        name: 'MUSA BESTO SHREDDED CHEESE 2kg',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png',
        price: 2750,
        isOnSale: false,
        category: 'Cheese',
      ),
    ];
  }

  List<WooCommerceProduct> _getFallbackSauces() {
    return [
      WooCommerceProduct(
        id: 34500,
        name: 'Nando’s XX Hot Peri-Peri Sauce 250g',
        price: 1250,
        isOnSale: false,
        image: 'assets/images/RestoMart_All_Category_Images_430x430/Sauces.png',
        category: 'Sauce',
      ),
      WooCommerceProduct(
        id: 34501,
        name: 'Nando’s Peri-Peri Medium Garlic Sauce 250g',
        price: 1250,
        isOnSale: false,
        image: 'assets/images/RestoMart_All_Category_Images_430x430/Sauces.png',
        category: 'Sauce',
      ),
      WooCommerceProduct(
        id: 1005,
        name: 'Tomato Ketchup 5kg Commercial Jar',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/Sauces.png',
        price: 1250,
        originalPrice: 1400,
        isOnSale: true,
        category: 'Sauces',
      ),
    ];
  }

  List<WooCommerceProduct> _getFallbackCanned() {
    return [
      WooCommerceProduct(
        id: 34601,
        name: 'DewDrop Bamboo Shoots (Halves)',
        price: 650,
        isOnSale: false,
        image: 'assets/images/RestoMart_All_Category_Images_430x430/11_Canned_Products.png',
        category: 'Canned',
      ),
      WooCommerceProduct(
        id: 34602,
        name: 'Dew Drop Jalapeno Sliced Peppers 320g',
        price: 580,
        isOnSale: false,
        image: 'assets/images/RestoMart_All_Category_Images_430x430/11_Canned_Products.png',
        category: 'Canned',
      ),
      WooCommerceProduct(
        id: 34603,
        name: 'DewDrop Canned Red Kidney Beans 380g',
        price: 420,
        isOnSale: false,
        image: 'assets/images/RestoMart_All_Category_Images_430x430/11_Canned_Products.png',
        category: 'Canned',
      ),
    ];
  }

  List<WooCommerceProduct> _getOfflineFallbackProducts() {
    return [
      WooCommerceProduct(
        id: 38214,
        name: 'Restomart Special Frozen Food Deal – Seekh Kebab, Kofta, Burger Patty & Nuggets',
        price: 1899,
        originalPrice: 2299,
        isOnSale: true,
        image: 'assets/images/RestoMart-Frozen-Food-Deal-Offer-430x430.png',
        category: 'Special Frozen Deal',
      ),
      WooCommerceProduct(
        id: 9902,
        name: 'RestoMart Special Frozen Food Mega Saver Pack',
        price: 2850,
        originalPrice: 3500,
        isOnSale: true,
        image: 'assets/images/RestoMart-Frozen-Food-Deal-Offer-430x430.png',
        category: 'Frozen Foods Deal',
      ),
      WooCommerceProduct(
        id: 9903,
        name: 'Mezan Perfect Frying Oil 16 Ltr Tin',
        price: 7490,
        originalPrice: 8990,
        isOnSale: true,
        image: 'assets/images/B2B-SKU-Mezan-Perfect-Frying-Oil-Tin-16-Ltr-430x430.webp',
        category: 'Weekly Oil Saver',
      ),
      WooCommerceProduct(
        id: 9904,
        name: 'Adams White Cheese Slices 1kg Pack',
        price: 1290,
        originalPrice: 1550,
        isOnSale: true,
        image: 'assets/images/Adams-Cheese-Slice-White-1kg-430x430.webp',
        category: 'Commercial Dairy',
      ),
      WooCommerceProduct(
        id: 1001,
        name: 'Mozzarella Cheese Shredded 2kg',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png',
        price: 2850,
        originalPrice: 3200,
        isOnSale: true,
        category: 'Cheese',
      ),
      WooCommerceProduct(
        id: 1002,
        name: 'Cheddar Cheese Block 1kg',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/01_Cheese.png',
        price: 1950,
        originalPrice: 2200,
        isOnSale: true,
        category: 'Cheese',
      ),
      WooCommerceProduct(
        id: 1003,
        name: 'Pure Cooking Oil 5L Can',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/03_Cooking_Oils.png',
        price: 2450,
        originalPrice: 2700,
        isOnSale: true,
        category: 'Cooking Oils',
      ),
      WooCommerceProduct(
        id: 1004,
        name: 'Special Garam Masala Pack 1kg',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/07_Spices.png',
        price: 850,
        originalPrice: 1000,
        isOnSale: true,
        category: 'Spices',
      ),
      WooCommerceProduct(
        id: 1005,
        name: 'Tomato Ketchup 5kg Commercial Jar',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/Sauces.png',
        price: 1250,
        originalPrice: 1400,
        isOnSale: true,
        category: 'Sauces',
      ),
      WooCommerceProduct(
        id: 1006,
        name: 'Paper Food Box 500 Pcs Pack',
        image: 'assets/images/RestoMart_All_Category_Images_430x430/05_Packaging_Materials.png',
        price: 1850,
        originalPrice: 2100,
        isOnSale: false,
        category: 'Packaging',
      ),
    ];
  }
}
