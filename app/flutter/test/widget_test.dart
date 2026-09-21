import 'package:flutter_test/flutter_test.dart';
import 'package:qi_flutter/main.dart';

void main() {
  testWidgets('Displays the Rust greeting', (tester) async {
    await tester.pumpWidget(const MyApp(greeting: 'Hello, Tom!'));

    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
