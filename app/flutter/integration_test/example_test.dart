import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:qi_flutter/main.dart';
import 'package:qi_flutter/src/rust/frb_generated.dart';

void main() {
  patrolTest('shows the greeting returned by Rust', ($) async {
    await RustLib.init();
    await $.pumpWidgetAndSettle(const MyApp());

    // Patrol finders also support interactions, e.g. `await $('Button').tap();`.
    expect($('flutter_rust_bridge quickstart'), findsOneWidget);
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
