// ─────────────────────────────────────────────────────────────────────────────
// dialog_validators.dart
//
// Composable validation rules for use with DialogField and any TextFormField.
//
// USAGE:
//   validators: [Validators.required()]
//   validators: [Validators.required(), Validators.email()]
//   validators: [Validators.required(), Validators.minLength(3)]
//
//   // Custom rule inline:
//   validators: [(v) => v == 'admin' ? 'Reserved username' : null]
//
//   // Compose manually:
//   final myRule = Validators.compose([Validators.required(), Validators.email()]);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// A single validation rule.
/// Returns an error string when invalid, or `null` when valid.
typedef ValidatorFn = String? Function(String? value);

abstract class Validators {
  // ── Required ──────────────────────────────────────────────────────────────

  /// Field must not be null or empty.
  static ValidatorFn required({String message = 'This field is required'}) {
    return (v) => (v == null || v.trim().isEmpty) ? message : null;
  }

  // ── Length ────────────────────────────────────────────────────────────────

  /// Value must have at least [min] characters.
  /// Skips the check when the field is empty — pair with [required] if needed.
  static ValidatorFn minLength(int min, {String? message}) {
    return (v) {
      if (v == null || v.isEmpty) return null;
      return v.length < min ? (message ?? 'Minimum $min characters') : null;
    };
  }

  /// Value must not exceed [max] characters.
  static ValidatorFn maxLength(int max, {String? message}) {
    return (v) => (v != null && v.length > max)
        ? (message ?? 'Maximum $max characters')
        : null;
  }

  // ── Format ────────────────────────────────────────────────────────────────

  /// Must be a valid e-mail address.
  static ValidatorFn email({String message = 'Enter a valid email address'}) {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return (v) =>
        (v != null && v.isNotEmpty && !re.hasMatch(v)) ? message : null;
  }

  /// Must be parseable as a number (integer or decimal).
  static ValidatorFn numeric({String message = 'Numbers only'}) {
    return (v) => (v != null && v.isNotEmpty && double.tryParse(v) == null)
        ? message
        : null;
  }

  /// Must be a number greater than zero.
  static ValidatorFn positiveNumber(
      {String message = 'Must be greater than 0'}) {
    return (v) {
      if (v == null || v.isEmpty) return null;
      final n = double.tryParse(v);
      return (n == null || n <= 0) ? message : null;
    };
  }

  /// Must match the provided regular expression.
  static ValidatorFn regex(RegExp pattern,
      {String message = 'Invalid format'}) {
    return (v) =>
        (v != null && v.isNotEmpty && !pattern.hasMatch(v)) ? message : null;
  }

  /// Must match the current value of [other] (e.g. confirm password).
  static ValidatorFn match(
    TextEditingController other, {
    String message = 'Values do not match',
  }) {
    return (v) => (v != other.text) ? message : null;
  }

  // ── Compose ───────────────────────────────────────────────────────────────

  /// Runs [validators] in order and returns the first error found, or null.
  ///
  /// Example:
  /// ```dart
  /// Validators.compose([Validators.required(), Validators.email()])
  /// ```
  static ValidatorFn compose(List<ValidatorFn> validators) {
    return (v) {
      for (final fn in validators) {
        final err = fn(v);
        if (err != null) return err;
      }
      return null;
    };
  }
}
