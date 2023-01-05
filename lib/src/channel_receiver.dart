import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChannelReceiver extends ChangeNotifier {
  MethodChannel _channel = const MethodChannel('flutter_interactive_keyboard');

  bool _initialized = false;
  init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'screenshotTaken':
          this.notifyListeners();
          break;
      }
    });
  }
}
