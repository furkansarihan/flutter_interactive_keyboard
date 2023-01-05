import 'dart:async';

import 'package:flutter/services.dart';

class ChannelManager {
  MethodChannel _channel = const MethodChannel('flutter_interactive_keyboard');

  bool _initialized = false;
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _channel.invokeMethod('init');
  }

  // True opens keyboard, false hides it
  Future<void> showKeyboard(bool show) async {
    await _channel.invokeMethod('showKeyboard', show);
  }

  Future<void> animate(bool animate) async {
    await _channel.invokeMethod('animate', animate);
  }

  Future<bool> expand() =>
      _channel.invokeMethod<bool>('expand').then((x) => x ?? false);

  Future<bool> fling(double velocity) =>
      _channel.invokeMethod<bool>('fling', velocity).then((x) => x ?? false);

  Future<void> updateScroll(double position) async {
    await _channel.invokeMethod('updateScroll', position);
  }

  Future<void> startScroll(double keyboardHeight) async {
    await _channel.invokeMethod('startScroll', keyboardHeight);
  }
}
