import 'package:flutter/material.dart';
import 'confirm_dialog.dart';

Future<bool> showLogoutDialog(BuildContext context) => showConfirmDialog(
  context,
  title: 'Logout?',
  message: 'Kamu akan keluar dari Eduvara.',
);
