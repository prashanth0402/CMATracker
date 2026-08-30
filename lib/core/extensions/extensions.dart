import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.errorContainer : null,
        ),
      );
  }
}

extension IterableNumX on Iterable<int> {
  int get sumOrZero => fold(0, (a, b) => a + b);
}

extension DoubleClampX on double {
  double clamp01() => clamp(0.0, 1.0).toDouble();
}
