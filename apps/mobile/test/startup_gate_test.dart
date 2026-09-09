import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nusarta/core/startup/startup_gate.dart';

void main() {
  test('startup routes signed out without waiting on optional work', () async {
    final update = Completer<void>();
    final result = await resolveStartup(
      configured: true,
      loggedIn: false,
      hasPin: update.future.then((_) => true),
      shouldLock: Future.value(false),
    );
    expect(result, StartupDestination.welcome);
  });
  test('startup fails safely when secure storage never resolves', () async {
    final result = await resolveStartup(
      configured: true,
      loggedIn: true,
      hasPin: Completer<bool>().future,
      shouldLock: Future.value(false),
    );
    expect(result, StartupDestination.error);
  });
  test('startup maps authenticated states', () async {
    expect(
        await resolveStartup(
            configured: true,
            loggedIn: true,
            hasPin: Future.value(false),
            shouldLock: Future.value(false)),
        StartupDestination.pinSetup);
    expect(
        await resolveStartup(
            configured: true,
            loggedIn: true,
            hasPin: Future.value(true),
            shouldLock: Future.value(true)),
        StartupDestination.lock);
    expect(
        await resolveStartup(
            configured: true,
            loggedIn: true,
            hasPin: Future.value(true),
            shouldLock: Future.value(false)),
        StartupDestination.home);
  });
  test('missing config fails clearly', () async {
    expect(
        await resolveStartup(
            configured: false,
            loggedIn: false,
            hasPin: Future.value(false),
            shouldLock: Future.value(false)),
        StartupDestination.error);
  });
}
