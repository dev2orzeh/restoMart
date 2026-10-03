// Splash module binding.
//
// Uses Get.put (not lazyPut) because we need the controller to
// initialize immediately — its onInit() triggers the 3-second
// delay then navigates to Login.
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
