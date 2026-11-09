import 'package:flutter/material.dart';
import 'package:qi_flutter/src/rust/api/core.dart';
import 'package:qi_flutter/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class const MyApp({super.key, final String? greeting}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
            'Action: Call Rust `greet("Tom")`\nResult: `${greeting ?? greet(name: "Tom")}`',
          ),
        ),
      ),
    );
  }
}
