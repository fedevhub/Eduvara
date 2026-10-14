import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final String message;
  const EmptyWidget({super.key, this.message = 'Belum ada data.'});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
