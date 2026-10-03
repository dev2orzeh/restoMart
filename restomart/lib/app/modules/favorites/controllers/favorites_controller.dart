import 'package:get/get.dart';

class FavoriteItem {
  final String id;
  final String imagePath;
  final String name;
  final double salePrice;
  final double originalPrice;
  final int discountPercent;

  FavoriteItem({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.salePrice,
    required this.originalPrice,
    required this.discountPercent,
  });
}

class FavoritesController extends GetxController {
  // Using the product name as the unique key for simplicity
  final RxMap<String, FavoriteItem> favorites = <String, FavoriteItem>{}.obs;

  bool isFavorite(String name) {
    return favorites.containsKey(name);
  }

  void toggleFavorite({
    required String id,
    required String imagePath,
    required String name,
    required double salePrice,
    required double originalPrice,
    required int discountPercent,
  }) {
    if (favorites.containsKey(name)) {
      favorites.remove(name);
      Get.snackbar(
        'Removed from Favorites',
        '$name has been removed.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
      );
    } else {
      favorites[name] = FavoriteItem(
        id: id,
        imagePath: imagePath,
        name: name,
        salePrice: salePrice,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
      );
      Get.snackbar(
        'Added to Favorites',
        '$name has been added!',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 1),
      );
    }
  }
}
