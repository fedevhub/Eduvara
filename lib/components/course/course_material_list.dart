import 'package:flutter/material.dart';
import '../../models/materi_model.dart';
import '../cards/material_card.dart';

class CourseMaterialList extends StatelessWidget {
  final List<Materi> materials;
  final ValueChanged<Materi>? onTap;
  const CourseMaterialList({super.key, required this.materials, this.onTap});

  @override
  Widget build(BuildContext context) => Column(
    children: materials
        .map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MaterialCard(material: m, onTap: () => onTap?.call(m)),
          ),
        )
        .toList(),
  );
}
