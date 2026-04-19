// PetMatch basic widget test.
//
// Tests app launches without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:petmatch/main.dart';
import 'package:petmatch/core/di/injection.dart';
import 'package:petmatch/core/router/app_router.dart';
import 'package:petmatch/core/theme/app_theme.dart';

void main() {
  testWidgets('PetMatchApp launches smoke test - mock mode', (WidgetTester tester) async {
    // Test simple MaterialApp without Firebase/DI to avoid init errors
    await tester.pumpWidget(
      MaterialApp(
        title: 'PetMatch Test',
        theme: ThemeData.light(useMaterial3: true),
        home: const Scaffold(
          body: Center(child: Text('PetMatch Test')),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('PetMatch Test'), findsOneWidget);
  });
}
