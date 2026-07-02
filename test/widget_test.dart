// Basic Flutter widget test for Sasmita Lens app.

import 'package:Sasmita_Lens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sasmita Lens app smoke test', (WidgetTester tester) async {
    // Build the app wrapped in ProviderScope (required by Riverpod).
    await tester.pumpWidget(
      const ProviderScope(
        child: SasmitaLensApp(),
      ),
    );

    // Allow splash animations and initial frame to settle.
    await tester.pump();

    // Verify the app renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
