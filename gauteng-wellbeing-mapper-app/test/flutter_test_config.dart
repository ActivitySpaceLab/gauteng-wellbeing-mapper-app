// Ensures a consistent test environment across CI and local by
// initializing sqflite to use FFI (no platform channels) and
// mocking SharedPreferences to avoid hitting platform code.
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Configure sqflite to use the FFI implementation to avoid native bindings.
  sqfliteFfiInit();
  sqflite.databaseFactory = databaseFactoryFfi;

  // Use mock SharedPreferences across tests unless explicitly overridden.
  SharedPreferences.setMockInitialValues({});

  // Mark environment as CI if set in Dart-define to ensure consistent behavior
  const bool isCI = bool.fromEnvironment('CI', defaultValue: false) ||
      bool.fromEnvironment('FLUTTER_TEST_MODE', defaultValue: false);
  if (isCI) {
    // Any additional global CI-only tweaks can go here.
  }

  await testMain();
}
