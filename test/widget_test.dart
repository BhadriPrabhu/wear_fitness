// import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: Ensure this import matches your actual project name. 
// Based on your error log, your project seems to be named 'wear_fitness'.
import 'package:wear_fitness/main.dart'; 

void main() {
  testWidgets('Dashboard UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartBandApp());

    // Verify that the main title of our new app is present.
    expect(find.text('CirculSense'), findsOneWidget);
    
    // Verify that the Live Vitals section is present.
    expect(find.text('Live Vitals Overview'), findsOneWidget);
  });
}