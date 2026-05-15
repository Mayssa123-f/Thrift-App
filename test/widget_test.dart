import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thrift_app/main.dart';

void main() {
  testWidgets('Vinty App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VintyApp());

    // Verify the app starts
    expect(find.byType(VintyApp), findsOneWidget);
  });
}