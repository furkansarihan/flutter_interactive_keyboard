import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_interactive_keyboard/src/channel_receiver.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'channel_manager.dart';

class KeyboardManagerWidget extends StatefulWidget {
  /// The widget behind the view where the drag to close is enabled
  final Widget child;
  final Widget footer;
  final ScrollController scrollController;
  final FocusNode focusNode;

  /// Optional variables for keyboard animation
  final double? defaultKeyboardSize;
  final Duration? duration;
  final Curve? curve;

  KeyboardManagerWidget({
    Key? key,
    required this.child,
    required this.footer,
    required this.scrollController,
    required this.focusNode,
    this.defaultKeyboardSize,
    this.duration,
    this.curve,
  }) : super(key: key);

  KeyboardManagerWidgetState createState() => KeyboardManagerWidgetState();
}

class KeyboardManagerWidgetState extends State<KeyboardManagerWidget> {
  /// Only initialised on IOS
  static ChannelReceiver channelReceiver = ChannelReceiver();
  static ChannelManager channelManager = ChannelManager();

  final List<int> pointers = [];
  int? get activePointer => pointers.length > 0 ? pointers.first : null;

  final List<double> velocities = [];
  final List<PointerMoveEvent> pointerEvents = [];
  double velocity = 0.0;
  int lastTime = 0;
  double lastPosition = 0.0;

  final ValueNotifier<bool> keyboardOpen = ValueNotifier(false);
  bool keyboardHeightFound = false;

  double keyboardHeight = 0.0;
  double over = 0.0;
  double startScrollOffset = 0;

  bool dismissed = true;
  bool dismissing = false;

  bool hasScreenshot = false;
  bool moving = false;
  bool keyboardMoving = false;

  late StreamSubscription<bool> keyboardSub;
  final ValueNotifier<KeyboardPaddingValue> bottomPadding = ValueNotifier(
    KeyboardPaddingValue(0, 0),
  );

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      channelReceiver.init();
      channelManager.init();
      channelReceiver.addListener(screenshotListener);
    }

    keyboardSub =
        KeyboardVisibilityController().onChange.listen(keyboardListener);
    widget.focusNode.addListener(focusListener);
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      channelReceiver.removeListener(screenshotListener);
    }
    keyboardSub.cancel();
    widget.focusNode.removeListener(focusListener);
    super.dispose();
  }

  void screenshotListener() {
    hasScreenshot = true;
  }

  void keyboardListener(bool visible) async {
    keyboardOpen.value = visible;
    if (visible && !widget.focusNode.hasFocus) return;
    if (moving) return;
    if (!visible && Platform.isIOS) return;
    if (visible && keyboardHeightFound) {
      setKeyboardPaddingValue(keyboardHeight);
      return;
    }
    if (!visible && !Platform.isIOS) {
      setKeyboardPaddingValue(0);
      return;
    }
    // TODO: better animation
    List<double> bottomList = [];
    if (!Platform.isIOS) {}
    while (true) {
      final bottom = MediaQuery.of(context).viewInsets.bottom;
      bottomList.add(bottom);
      if (bottom != 0) {
        setKeyboardPaddingValue(bottom);
      }
      final size = 50;
      if (bottomList.length > size) {
        final lastChunk = bottomList.sublist(
          bottomList.length - size,
          bottomList.length,
        );
        if (lastChunk.toSet().toList().length == 1) {
          keyboardHeightFound = true;
          // log('keyboardListener: end keyboard move');
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void focusListener() {
    if (!widget.focusNode.hasFocus) {
      setKeyboardPaddingValue(0);
    }
  }

  void setKeyboardPaddingValue(double newValue) {
    if (newValue == 0 && !Platform.isIOS) {
      FocusScope.of(context).requestFocus(FocusNode());
    }
    bottomPadding.value = KeyboardPaddingValue(
      newValue,
      bottomPadding.value.padding,
    );
  }

  bool isFlicked() {
    if (pointerEvents.isEmpty) return false;
    final lastUpdates = pointerEvents.take(3).toList();
    for (var element in lastUpdates) {
      if (element.delta.dy.abs() > 5) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var bottom = MediaQuery.of(context).viewInsets.bottom;
    if (bottom > keyboardHeight) keyboardHeight = bottom;

    if (keyboardOpen.value) {
      dismissed = false;
    }

    return Listener(
      onPointerDown: (details) {
        moving = true;
        var position = details.position.dy;
        over = position - (MediaQuery.of(context).size.height - keyboardHeight);
        startScrollOffset = widget.scrollController.offset - over;
        // log("pointerDown $dismissed $activePointer ${keyboardOpen.value} ${pointers.length} $dismissing");
        if ((!dismissed && !dismissing) || keyboardOpen.value) {
          pointers.add(details.pointer);
          if (pointers.length == 1) {
            if (Platform.isIOS) {
              channelManager
                  .startScroll(MediaQuery.of(context).viewInsets.bottom);
            }
            lastPosition = details.position.dy;
            lastTime = DateTime.now().millisecondsSinceEpoch;
            velocities.clear();
          }
        }
      },
      onPointerUp: (details) {
        moving = false;
        keyboardMoving = false;
        // log("pointerUp $velocity, $over, ${details.pointer}, $activePointer");
        if (details.pointer != activePointer || pointers.length != 1) {
          pointers.remove(details.pointer);
          return;
        }
        if (!widget.focusNode.hasFocus) {
          // log('onPointerUp: ${widget.focusNode.hasFocus}');
          pointers.remove(details.pointer);
          return;
        }
        if (Platform.isIOS && over > 0) {
          if (isFlicked() && velocity > 0) {
            channelManager.fling(velocity);
            setKeyboardPaddingValue(0);
            dismissed = true;
          } else {
            setKeyboardPaddingValue(keyboardHeight);
            channelManager.expand();
            widget.focusNode.requestFocus();
            Future.delayed(
                const Duration(milliseconds: 100), () => showKeyboard(false));
          }
        } else {
          setKeyboardPaddingValue(keyboardHeight);
          if (Platform.isIOS) {
            channelManager.expand();
          }
          widget.focusNode.requestFocus();
          Future.delayed(
              const Duration(milliseconds: 100), () => showKeyboard(false));
        }
        pointers.remove(details.pointer);
      },
      onPointerMove: (details) {
        pointerEvents.insert(0, details);
        moving = true;
        // log("pointerMove $over, $activePointer, ${details.pointer}");
        if (details.pointer == activePointer && widget.focusNode.hasFocus) {
          var position = details.position.dy;
          over =
              position - (MediaQuery.of(context).size.height - keyboardHeight);
          updateVelocity(position);
          // log("pointerMove $over, $activePointer, ${details.pointer}");
          if (over > 0) {
            keyboardMoving = true;
            setKeyboardPaddingValue(keyboardHeight - over);
          } else {
            setKeyboardPaddingValue(keyboardHeight);
          }
          if (over > 0) {
            widget.scrollController.jumpTo(widget.scrollController.offset);
            if (Platform.isIOS) {
              if (keyboardOpen.value && hasScreenshot) hideKeyboard(false);
              channelManager.updateScroll(over);
            } else {
              if (velocity > 0.1) {
                if (keyboardOpen.value) {
                  hideKeyboard(true);
                }
              } else if (velocity < -0.5) {
                if (!keyboardOpen.value) {
                  showKeyboard(true);
                }
              }
            }
          } else {
            if (keyboardMoving) {
              final offset = startScrollOffset + over;
              // log('keyboardMoving: startSrollOffset: $startScrollOffset offset: $offset');
              if (offset > 0) {
                widget.scrollController.jumpTo(offset);
              }
            }
            if (Platform.isIOS) {
              channelManager.updateScroll(over);
              if (!keyboardOpen.value) {
                channelManager.expand();
              }
            } else {
              if (!keyboardOpen.value) {
                showKeyboard(false);
              }
            }
          }
        }
      },
      onPointerCancel: (details) {
        moving = false;
        keyboardMoving = false;
        pointers.remove(details.pointer);
      },
      child: Column(
        children: [
          Expanded(child: widget.child),
          widget.footer,
          ValueListenableBuilder<KeyboardPaddingValue>(
            valueListenable: bottomPadding,
            builder: (context, value, child) {
              final keyboardSize = keyboardHeightFound
                  ? keyboardHeight
                  : widget.defaultKeyboardSize ?? 300;
              final durationMilli = widget.duration?.inMilliseconds ??
                  (Platform.isIOS ? 500 : 250);
              final curve = widget.curve ??
                  (Platform.isIOS
                      ? Cubic(.29, .73, .13, 1)
                      : Curves.easeOutCubic);
              Duration duration;
              double distance = (value.prevPadding - value.padding).abs();
              if (distance > 0) {
                final milli = distance * durationMilli / keyboardSize;
                duration = Duration(milliseconds: milli.ceil());
              } else {
                duration = const Duration();
              }
              // log('ValueListenableBuilder: padding: ${value.padding}, prevPadding: ${value.prevPadding}, distance: $distance, duration: ${duration.inMilliseconds}');
              return AnimatedContainer(
                duration: duration,
                curve: curve,
                height: value.padding,
              );
            },
          ),
        ],
      ),
    );
  }

  updateVelocity(double position) {
    var time = DateTime.now().millisecondsSinceEpoch;
    if (time - lastTime > 0) {
      velocity = (position - lastPosition) / (time - lastTime);
    }
    lastPosition = position;
    lastTime = time;
  }

  showKeyboard(bool animate) {
    if (!animate && Platform.isIOS) {
      channelManager.showKeyboard(true);
    } else {
      _showKeyboard();
    }
  }

  _showKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  hideKeyboard(bool animate) {
    if (!animate && Platform.isIOS) {
      channelManager.showKeyboard(false);
    } else {
      _hideKeyboard();
    }
  }

  _hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> removeImageKeyboard() async {
    channelManager.updateScroll(keyboardHeight);
  }

  Future<void> safeHideKeyboard() async {
    await removeImageKeyboard();
    _hideKeyboard();
  }
}

class KeyboardPaddingValue {
  const KeyboardPaddingValue(this.padding, this.prevPadding);
  final double padding;
  final double prevPadding;
}
