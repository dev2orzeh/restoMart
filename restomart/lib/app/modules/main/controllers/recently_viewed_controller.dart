import 'package:get/get.dart';

class RecentlyViewedProduct {
  final String imagePath;
  final List<String>? imagePaths;
  final String name;
  final String category;
  final double price;
  final double originalPrice;
  final double discountPercent;

  RecentlyViewedProduct({
    required this.imagePath,
    this.imagePaths,
    required this.name,
    this.category = '',
    required this.price,
    this.originalPrice = 0.0,
    this.discountPercent = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentlyViewedProduct &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class RecentlyViewedController extends GetxController {
  final RxList<RecentlyViewedProduct> viewedProducts = <RecentlyViewedProduct>[].obs;

  void addProduct(RecentlyViewedProduct product) {
    // Remove if it already exists to put it at the front
    viewedProducts.removeWhere((p) => p.name == product.name);
    
    // Insert at front
    viewedProducts.insert(0, product);
    
    // Keep only the 10 most recent
    if (viewedProducts.length > 10) {
      viewedProducts.removeLast();
    }
  }
}
