import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorStateWidget({
    super.key,
    this.message = 'Terjadi kesalahan.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 44),
        const SizedBox(height: 10),
        Text(message),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}
