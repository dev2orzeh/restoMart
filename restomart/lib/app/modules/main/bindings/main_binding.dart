import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/recently_viewed_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.put<NotificationsController>(NotificationsController());
    Get.put<RecentlyViewedController>(RecentlyViewedController());
  }
}
