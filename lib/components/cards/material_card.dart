import 'package:flutter/material.dart';
import '../../models/materi_model.dart';
import '../../core/constants/app_colors.dart';

class MaterialCard extends StatelessWidget {
  final Materi material;
  final VoidCallback? onTap;
  const MaterialCard({super.key, required this.material, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.description_outlined, color: AppColors.primary),
    ),
    title: Text(
      material.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      material.content,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.chevron_right),
  );
}
