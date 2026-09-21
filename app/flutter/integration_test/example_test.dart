import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:qi_flutter/main.dart'; // Adjust if main.dart doesn't expose the app

void main() {
  patrolTest(
    'example integration test using Patrol',
    ($) async {
      // Pump the app
      await $.pumpWidgetAndSettle(const MyApp()); // Ensure your main app widget is named MyApp

      // Example of Patrol UI interaction
      // await $('Button Text').tap();
      // await $('Counter').waitUntilVisible();
      
      expect($('FlutterRustApp'), findsNothing); // Example assertion
    },
  );
}
