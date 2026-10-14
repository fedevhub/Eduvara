import 'package:flutter/material.dart';
import 'confirm_dialog.dart';

Future<bool> showDeleteDialog(BuildContext context) => showConfirmDialog(
  context,
  title: 'Hapus data?',
  message: 'Data yang dihapus tidak dapat dikembalikan.',
);
