package com.ujiboo.flutter_interactive_keyboard

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterInteractiveKeyboardPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onMethodCall(call: MethodCall, result: Result) {
    result.notImplemented()
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "flutter_interactive_keyboard")
    channel.setMethodCallHandler(FlutterInteractiveKeyboardPlugin())
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}