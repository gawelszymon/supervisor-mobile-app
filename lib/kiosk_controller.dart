import 'package:flutter/services.dart';

class KioskController {
  static const _channel = MethodChannel("kiosk_controller");

  static Future<void> startKiosk() async {
    await _channel.invokeMethod("startLockTask");
  }

  static Future<void> stopKiosk() async {
    await _channel.invokeMethod("stopLockTask");
  }
}
