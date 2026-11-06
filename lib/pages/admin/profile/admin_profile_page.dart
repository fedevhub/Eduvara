import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../components/ui/kit.dart';
import '../../../core/routes/route_names.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _db = Supabase.instance.client;
  late Future<Map<String, dynamic>> _settings;

  @override
  void initState() {
    super.initState();
    _settings = _loadSettings();
  }

  Future<Map<String, dynamic>> _loadSettings() async =>
      Map<String, dynamic>.from(
        await _db
            .from('school_settings')
            .select('school_name, academic_year, class_count')
            .eq('id', 1)
            .single(),
      );

  Future<void> _editSetting({
    required String title,
    required String column,
    required String currentValue,
    required bool numeric,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(labelText: title),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return '$title wajib diisi.';
              if (numeric && int.tryParse(text) == null) {
                return 'Masukkan angka yang valid.';
              }
              if (column == 'academic_year' &&
                  !RegExp(r'^\d{4}/\d{4}$').hasMatch(text)) {
                return 'Gunakan format tahun ajaran, contoh 2026/2027.';
              }
              if (numeric && int.parse(text) < 0) {
                return 'Nilai tidak boleh negatif.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;

    try {
      await _db
          .from('school_settings')
          .update({column: numeric ? int.parse(value) : value})
          .eq('id', 1);
      if (!mounted) return;
      setState(() => _settings = _loadSettings());
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan $title: ${error.message}')),
      );
    }
  }

  Future<void> _logout() async {
    final ok = await showConfirmWarning(
      context,
      title: 'Keluar dari panel admin?',
      message: 'Kamu akan keluar dari Eduvara.',
      primary: 'Ya, Keluar',
    );
    if (!ok || !mounted) return;

    try {
      await _db.auth.signOut();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar: ${error.message}')));
      return;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (route) => false,
    );
  }

  Widget _settingRow(
    String title,
    String value, {
    required String column,
    required bool numeric,
    required bool last,
    String? editValue,
  }) => _Row(
    title,
    value,
    last: last,
    onEdit: () => _editSetting(
      title: title,
      column: column,
      currentValue: editValue ?? value,
      numeric: numeric,
    ),
  );

  @override
  Widget build(BuildContext context) => EduScaffold(
    scroll: false,
    bottom: const EduBottomNav(role: 'admin', current: 3),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        const Text(
          'Setting',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'INFORMASI SEKOLAH',
          style: TextStyle(fontSize: 8, color: Ui.muted),
        ),
        const SizedBox(height: 6),
        FutureBuilder<Map<String, dynamic>>(
          future: _settings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const EduCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return EduCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pengaturan sekolah belum dapat dimuat.'),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(fontSize: 9, color: Ui.red),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _settings = _loadSettings()),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              );
            }

            final settings = snapshot.data!;
            return EduCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  _settingRow(
                    'Nama Sekolah',
                    settings['school_name'].toString(),
                    column: 'school_name',
                    numeric: false,
                    last: false,
                  ),
                  _settingRow(
                    'Tahun Ajaran',
                    settings['academic_year'].toString(),
                    column: 'academic_year',
                    numeric: false,
                    last: false,
                  ),
                  _settingRow(
                    'Jumlah Kelas',
                    '${settings['class_count']} Kelas',
                    column: 'class_count',
                    numeric: true,
                    last: true,
                    editValue: settings['class_count'].toString(),
                  ),
                ],
              ),
            );
          },
        ),
        const Spacer(),
        GestureDetector(
          onTap: _logout,
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Ui.redTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Ui.red.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, size: 15, color: Ui.red),
                SizedBox(width: 6),
                Text(
                  'Keluar dari panel admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Ui.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const EduFooter(),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String title;
  final String value;
  final bool last;
  final VoidCallback onEdit;

  const _Row(this.title, this.value, {required this.onEdit, this.last = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
    ),
    child: Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 9))),
        Text(value, style: const TextStyle(fontSize: 9)),
        IconButton(
          tooltip: 'Edit $title',
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 15),
          color: Ui.blue,
        ),
      ],
    ),
  );
}
