import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/widgets/finance_load_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('network, auth, database and unexpected failures remain distinct', () {
    final network =
        FinanceLoadError.messageFor(const SocketException('offline'));
    expect(FinanceLoadError.messageFor(TimeoutException('timeout')), network);
    final auth = FinanceLoadError.messageFor(const AuthException('expired'));
    final database = FinanceLoadError.messageFor(
        const PostgrestException(message: 'unavailable', code: '42P01'));
    final unknown = FinanceLoadError.messageFor(StateError('invalid response'));
    expect({network, auth, database, unknown}, hasLength(4));
  });
  testWidgets('retry is actionable without exposing raw server details',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FinanceLoadError(
      error: const PostgrestException(
          message: 'private diagnostic', code: '42P01'),
      onRetry: () => retries++,
    ))));
    expect(find.textContaining('private diagnostic'), findsNothing);
    await tester.tap(find.text('Coba lagi'));
    expect(retries, 1);
  });
}
