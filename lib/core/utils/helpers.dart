import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_strings.dart';

/// Thrown when someone signs up with an email that already has an account.
class EmailAlreadyRegisteredException implements Exception {}

class PhoneUtils {
  PhoneUtils._();

  /// Turns "098765 43210", "9876543210" or "+91 98765-43210" into
  /// "+919876543210". Returns null if it doesn't look like a phone number.
  static String? normalize(String input) {
    var s = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    if (s.startsWith('+')) {
      return (s.length >= 11 && s.length <= 16) ? s : null;
    }
    if (s.startsWith('0') && s.length == 11) s = s.substring(1);
    if (s.length == 10) return '+91$s';
    if (s.length == 12 && s.startsWith('91')) return '+$s';
    return null;
  }
}

class Validators {
  Validators._();

  static FormFieldValidator<String> required(BuildContext context) =>
      (v) => (v == null || v.trim().isEmpty) ? context.tr('err_required') : null;

  static FormFieldValidator<String> email(BuildContext context) => (v) {
        final s = v?.trim() ?? '';
        if (s.isEmpty) return context.tr('err_required');
        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
        return ok ? null : context.tr('err_email');
      };

  static FormFieldValidator<String> password(BuildContext context) =>
      (v) => (v == null || v.length < 8) ? context.tr('err_password') : null;

  static FormFieldValidator<String> phone(BuildContext context) =>
      (v) => PhoneUtils.normalize(v ?? '') == null ? context.tr('err_phone') : null;
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? scheme.error : null,
    ));
}

/// Turns any error into a short message a user can act on.
String friendlyError(BuildContext context, Object error) {
  final raw = error.toString();
  if (error is SocketException ||
      error is TimeoutException ||
      raw.contains('SocketException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('ClientException')) {
    return context.tr('err_offline');
  }
  if (error is EmailAlreadyRegisteredException) return context.tr('already_registered');
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    if (error.code == '23505') return context.tr('err_duplicate');
    return error.message;
  }
  if (error is StorageException) return error.message;
  return context.tr('err_generic');
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('cancel')),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
