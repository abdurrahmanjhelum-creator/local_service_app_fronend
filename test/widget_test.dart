import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_services_app/main.dart';

void main() {
  testWidgets('App starts', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LocalServicesApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
