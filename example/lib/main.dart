import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_interactive_keyboard/flutter_interactive_keyboard.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FocusNode focusNode = FocusNode();
  ScrollController controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Interactive Keyboard'),
        actions: [
          CupertinoButton(
            child: Icon(
              Icons.arrow_right_alt_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return MyApp();
                },
              ));
            },
          ),
        ],
      ),
      body: KeyboardManagerWidget(
        scrollController: controller,
        focusNode: focusNode,
        child: ListView.builder(
          itemCount: 100,
          reverse: true,
          controller: controller,
          itemBuilder: (context, index) {
            return Row(
              mainAxisAlignment: index % 3 == 1
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: index % 3 == 1 ? Colors.blueGrey : Colors.blueAccent,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "message $index",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        footer: Container(
          margin: EdgeInsets.fromLTRB(8, 0, 8, 8),
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: TextField(
            autofocus: false,
            keyboardAppearance: Brightness.light,
            focusNode: focusNode,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
