import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('probe bare ExpansionTile', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: ListView(children: const [
        ExpansionTile(
          title: Text('Q1'),
          children: [Text('ANS1')],
        ),
      ]),
    )));
    final q = find.text('Q1');
    await tester.ensureVisible(q);
    await tester.pumpAndSettle();
    await tester.tap(q);
    await tester.pumpAndSettle();
    debugPrint('ANK1=${tester.any(find.text('ANS1'))}');
    debugPrint('TAP_MISSED=${true}');
  });
}
