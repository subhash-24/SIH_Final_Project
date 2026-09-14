import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:patient_app/main.dart';
import 'package:patient_app/state/app_state.dart';

void main() {
  testWidgets('ArogyaSaathiApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const ArogyaSaathiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app starts on welcome screen
    expect(find.text('Welcome to Arogya-Saathi'), findsOneWidget);
  });
}
