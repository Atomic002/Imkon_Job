import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogShown = false;

  /// ✅ ASYNC INIT - main.dart'dan chaqiriladi
  Future<ConnectivityService> init() async {
    try {
      print('🌐 ConnectivityService initializing...');

      // Dastlabki connection tekshirish
      await _checkInitialConnection();

      // Stream'ni boshlash
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          _updateConnectionStatus(results);
        },
        onError: (error) {
          print('⚠️ Connectivity stream error: $error');
        },
      );

      print('✅ ConnectivityService ready');
      return this;
    } catch (e) {
      print('❌ ConnectivityService init error: $e');
      // Xato bo'lsa ham davom etish (default true)
      isConnected.value = true;
      return this;
    }
  }

  /// ✅ Dastlabki connection tekshirish
  Future<void> _checkInitialConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results, isInitial: true);
    } catch (e) {
      print('⚠️ Initial connection check error: $e');
      isConnected.value = true; // Default true
    }
  }

  /// ✅ Connection status yangilash
  void _updateConnectionStatus(
    List<ConnectivityResult> results, {
    bool isInitial = false,
  }) {
    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    final previousStatus = isConnected.value;
    isConnected.value = hasConnection;

    print('🌐 Connection status: ${hasConnection ? "✅ Online" : "❌ Offline"}');

    // ✅ Faqat status o'zgarsa dialog/snackbar ko'rsatish
    if (previousStatus != hasConnection) {
      if (!hasConnection) {
        _showNoInternetDialog();
      } else {
        _hideNoInternetDialog();

        // Faqat dialog ko'rsatilgan bo'lsa snackbar ko'rsatish
        if (_isDialogShown && !isInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.context != null) {
              Get.snackbar(
                '✅ Internet qayta ulandi',
                'Endi ilovadan foydalanishingiz mumkin',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
                margin: const EdgeInsets.all(10),
                icon: const Icon(Icons.wifi, color: Colors.white),
              );
            }
          });
        }
      }
    }
  }

  /// ✅ Internet yo'q dialogini ko'rsatish
  void _showNoInternetDialog() {
    if (_isDialogShown) return;

    // GetX context mavjudligini tekshirish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) {
        print('⚠️ GetX context null, dialog not shown');
        // 500ms kutib qayta urinish
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isConnected.value) {
            _showNoInternetDialog();
          }
        });
        return;
      }

      if (_isDialogShown) return; // Double check
      _isDialogShown = true;

      try {
        Get.dialog(
          PopScope(
            canPop: false,
            child: Material(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 64,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Internet yo\'q',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Iltimos, internetga ulaning va qayta urinib ko\'ring',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final results = await _connectivity
                                  .checkConnectivity();
                              _updateConnectionStatus(results);
                            } catch (e) {
                              print('⚠️ Manual check error: $e');
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Qayta tekshirish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          barrierDismissible: false,
          barrierColor: Colors.transparent,
        );
      } catch (e) {
        print('❌ Show dialog error: $e');
        _isDialogShown = false;
      }
    });
  }

  /// ✅ Internet yo'q dialogini yashirish
  void _hideNoInternetDialog() {
    if (_isDialogShown) {
      try {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (e) {
        print('⚠️ Hide dialog error: $e');
      } finally {
        _isDialogShown = false;
      }
    }
  }

  @override
  void onClose() {
    print('🌐 ConnectivityService closing...');
    _subscription?.cancel();

    if (_isDialogShown && (Get.isDialogOpen == true)) {
      try {
        Get.back();
      } catch (e) {
        print('⚠️ Close dialog error: $e');
      }
    }

    super.onClose();
  }
}
