import 'package:flutter/material.dart';
import '../../../components/navigation/app_bar.dart';
import '../../../components/forms/material_form.dart';

class AdminMaterialFormPage extends StatelessWidget {
  const AdminMaterialFormPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const EduvaraAppBar(title: 'Tambah Materi', showBack: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: MaterialForm(onSubmit: () => Navigator.pop(context)),
    ),
  );
}
