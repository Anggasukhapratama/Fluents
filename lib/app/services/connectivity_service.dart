// lib/app/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Status koneksi reaktif
  final isConnected = true.obs;
  final isCheckingConnection = false.obs;

  // Untuk cegah snackbar ganda
  bool _lastConnected = true;
  bool _initialized = false;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  Future<void> _initConnectivity() async {
    // Cek status awal
    try {
      final results = await _connectivity.checkConnectivity();
      final connected = _isConnected(results);
      isConnected.value = connected;
      _lastConnected = connected;
    } catch (_) {}

    // Listen perubahan koneksi
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final connected = _isConnected(results);
        isConnected.value = connected;

        if (!_initialized) {
          _initialized = true;
          _lastConnected = connected;
          return;
        }

        // Hanya tampilkan notif jika status berubah
        if (connected == _lastConnected) return;
        _lastConnected = connected;

        if (!connected) {
          _showNoInternetBanner();
        } else {
          _showConnectedSnackbar();
        }
      },
    );

    _initialized = true;
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  void _showNoInternetBanner() {
    // Tutup snackbar aktif dulu
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();

    Get.rawSnackbar(
      messageText: Row(
        children: const [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tidak Ada Koneksi Internet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Periksa koneksi WiFi atau data seluler Anda.',
                  style: TextStyle(
                    color: Color(0xFFFFCDD2),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE53935),
      borderRadius: 14,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      duration: const Duration(days: 1), // tampil terus sampai koneksi kembali
      isDismissible: false,
      snackPosition: SnackPosition.TOP,
      animationDuration: const Duration(milliseconds: 350),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  void _showConnectedSnackbar() {
    // Tutup banner "tidak ada internet" dulu
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();

    Future.delayed(const Duration(milliseconds: 200), () {
      Get.rawSnackbar(
        messageText: Row(
          children: const [
            Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Koneksi Kembali! ✅',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Internet telah terhubung kembali.',
                    style: TextStyle(
                      color: Color(0xFFA5F3D0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        borderRadius: 14,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        isDismissible: true,
        snackPosition: SnackPosition.TOP,
        animationDuration: const Duration(milliseconds: 350),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
      );
    });
  }
}
