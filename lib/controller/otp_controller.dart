import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OTPController extends GetxController {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  final countdown = 60.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    startCountdown();
  }

  void startCountdown() {
    countdown.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (countdown.value > 0) {
        countdown.value--;
        return true;
      }
      return false;
    });
  }

  void resendCode() {
    startCountdown();
    Get.snackbar(
      'success'.tr,
      'code_sent'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF10B981),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<void> verifyOTP() async {
    String otp = otpControllers.map((c) => c.text).join();
    if (otp.length == 6) {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1));
      isLoading.value = false;

      Get.offAllNamed('/home');
      Get.snackbar(
        'success'.tr,
        'account_created'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'Iltimos, 6 raqamli kodni to\'liq kiriting',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  void onClose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.onClose();
  }
}
