import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/assistant/ui/ndimbal.dart';

void main() {
  testWidgets('Ndimbal peint les frontières du salut sans erreur', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Ndimbal(taille: 100, pose: PoseNdimbal.salut)),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 480));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 780));
    expect(tester.takeException(), isNull);
  });
}
