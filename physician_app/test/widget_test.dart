import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:physician_app/main.dart';
import 'package:physician_app/screens/login_screen.dart';

void main() {
  testWidgets('Physician portal smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
      ],
    );

    await tester.pumpWidget(PhysicianApp(router: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('Arogya-Saathi'), findsOneWidget);
    expect(find.text('Physician Authentication'), findsOneWidget);
  });
}
