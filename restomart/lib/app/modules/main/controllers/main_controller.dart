import 'package:get/get.dart';

class MainController extends GetxController {
  // 0: Categories, 1: Promotions, 2: Home, 3: Notifications, 4: Account
  final RxInt currentIndex = 2.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}
