import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class Ui {
  static const bg = Color(0xFFF8FAFC);
  static const blue = Color(0xFF2563EB);
  static const blueDark = Color(0xFF1D4ED8);
  static const blueSoft = Color(0xFFDBE6FC);
  static const blueTint = Color(0xFFEAF0FF);
  static const navy = Color(0xFF1E293B);
  static const text = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const green = Color(0xFF22C55E);
  static const greenDark = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const navGreen = Color(0xFFBBF7D0);
  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0xFFFECACA);
  static const redTint = Color(0xFFFEE2E2);
  static const orange = Color(0xFFF59E0B);
  static const orangeDark = Color(0xFFD97706);
  static const yellowSoft = Color(0xFFFEF3C7);

  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  static const gradientTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFF93B4F8), blue],
  );
}

class EduCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;
  final Color color;

  const EduCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.borderColor,
    this.radius = 12,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.3),
        boxShadow: Ui.shadow,
      ),
      child: child,
    ),
  );
}

class EduScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  final Widget? bottomBar;
  final bool scroll;
  final EdgeInsetsGeometry padding;

  const EduScaffold({
    super.key,
    required this.body,
    this.bottom,
    this.bottomBar,
    this.scroll = true,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Ui.bg,
    body: SafeArea(
      bottom: bottom == null && bottomBar == null,
      child: scroll
          ? SingleChildScrollView(padding: padding, child: body)
          : Padding(padding: padding, child: body),
    ),
    bottomNavigationBar: bottomBar ?? bottom,
  );
}

class BackLink extends StatelessWidget {
  final Color color;
  const BackLink({super.key, this.color = Ui.text});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.maybePop(context),
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 16, color: color),
          const SizedBox(width: 6),
          Text('Kembali', style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    ),
  );
}

class PageTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;
  const PageTitle(this.title, {super.key, this.onAdd});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Ui.text,
          ),
        ),
      ),
      if (onAdd != null)
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Ui.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
    ],
  );
}

class DarkAvatar extends StatelessWidget {
  final double size;
  const DarkAvatar({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(color: Ui.navy, shape: BoxShape.circle),
    child: Icon(Icons.person, color: Colors.white, size: size * 0.55),
  );
}

enum PillKind { active, inactive, running, done, locked, draft }

class Pill extends StatelessWidget {
  final String text;
  final PillKind kind;
  const Pill(this.text, {super.key, this.kind = PillKind.active});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      PillKind.active || PillKind.done => (Ui.greenSoft, Ui.greenDark),
      PillKind.inactive => (Ui.redTint, Ui.red),
      PillKind.running => (Ui.blueTint, Ui.blue),
      PillKind.locked => (Ui.yellowSoft, Ui.orangeDark),
      PillKind.draft => (const Color(0xFFE2E8F0), Ui.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class SegTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const SegTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Ui.blueSoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: i == index ? Ui.shadow : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                    color: Ui.text,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class FilterChips extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const FilterChips({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        GestureDetector(
          onTap: () => onChanged(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: i == index ? Ui.blue : Ui.blueTint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Ui.blue.withValues(alpha: 0.6)),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: i == index ? Colors.white : Ui.text,
              ),
            ),
          ),
        ),
    ],
  );
}

class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool pill;
  const SearchBox({
    super.key,
    this.hint = 'Cari Pengguna',
    this.onChanged,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(pill ? 20 : 10),
      border: Border.all(color: Ui.line),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB6BFCC)),
            ),
          ),
        ),
        const Icon(Icons.search, size: 17, color: Ui.muted),
      ],
    ),
  );
}

class SoftBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final double height;

  const SoftBtn({
    super.key,
    required this.label,
    this.icon,
    this.bg = Ui.blueSoft,
    this.fg = Ui.blue,
    this.onTap,
    this.height = 34,
  });

  const SoftBtn.edit({super.key, this.label = 'Edit', this.onTap})
    : icon = Icons.edit_outlined,
      bg = Ui.blueSoft,
      fg = Ui.blue,
      height = 34;

  const SoftBtn.delete({super.key, this.label = 'Hapus', this.onTap})
    : icon = Icons.delete_outline,
      bg = Ui.redSoft,
      fg = Ui.red,
      height = 34;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    ),
  );
}

class SolidBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final IconData? leading;
  final IconData? trailing;
  final double height;
  final double radius;

  const SolidBtn({
    super.key,
    required this.label,
    this.onTap,
    this.bg = Ui.navy,
    this.fg = Colors.white,
    this.leading,
    this.trailing,
    this.height = 40,
    this.radius = 7,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: onTap == null ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Icon(leading, size: 15, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Icon(trailing, size: 15, color: fg),
          ],
        ],
      ),
    ),
  );
}

class ProgressLine extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const ProgressLine({
    super.key,
    required this.value,
    this.color = Ui.blue,
    this.height = 5,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      minHeight: height,
      backgroundColor: const Color(0xFFE2E8F0),
      valueColor: AlwaysStoppedAnimation(color),
    ),
  );
}

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final bool tall;
  const StatBox({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) => EduCard(
    padding: EdgeInsets.symmetric(vertical: tall ? 14 : 10, horizontal: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Ui.greenSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Ui.greenDark),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: tall ? 24 : 18,
            fontWeight: FontWeight.w800,
            color: Ui.blue,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Ui.muted)),
      ],
    ),
  );
}

class LockedCard extends StatelessWidget {
  final Widget child;
  final String text;
  const LockedCard({
    super.key,
    required this.child,
    this.text = 'Selesaikan Modul Sebelumnya',
  });

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: child,
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Ui.navy,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.lock, size: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Ui.text,
            ),
          ),
        ],
      ),
    ],
  );
}

class EduFooter extends StatelessWidget {
  final String text;
  const EduFooter({super.key, this.text = 'Eduvara Admin v1.0.0 • SMK Negeri 8 Malang'});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: const TextStyle(fontSize: 9, color: Ui.muted),
    ),
  );
}

Future<bool> showEduDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String title,
  String? message,
  required String primary,
  Color primaryColor = Ui.orange,
  String? secondary = 'Batal',
}) async {
  final res = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 3),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8.5, color: Ui.muted),
              ),
            ],
            const SizedBox(height: 14),
            SolidBtn(
              label: primary,
              bg: primaryColor,
              height: 30,
              onTap: () => Navigator.pop(ctx, true),
            ),
            if (secondary != null) ...[
              const SizedBox(height: 8),
              SolidBtn(
                label: secondary,
                bg: Ui.blueTint,
                fg: Ui.text,
                height: 30,
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  return res ?? false;
}

Future<bool> showConfirmWarning(
  BuildContext context, {
  required String title,
  String? message,
  String primary = 'Ya, Konfirmasi',
}) => showEduDialog(
  context,
  icon: Icons.warning_amber_rounded,
  iconColor: Ui.orange,
  iconBg: Ui.yellowSoft,
  title: title,
  message: message,
  primary: primary,
);

Future<bool> showConfirmDanger(
  BuildContext context, {
  required String title,
  String? message,
  String primary = 'Ya, Hapus',
}) => showEduDialog(
  context,
  icon: Icons.delete_outline,
  iconColor: Ui.red,
  iconBg: Ui.redTint,
  title: title,
  message: message,
  primary: primary,
  primaryColor: Ui.red,
);

Future<void> showSuccessDialog(BuildContext context, String message) =>
    showEduDialog(
      context,
      icon: Icons.check_circle_outline,
      iconColor: Ui.green,
      iconBg: Ui.greenSoft,
      title: message,
      primary: 'OKE',
      primaryColor: Ui.green,
      secondary: null,
    );

class FormCard extends StatelessWidget {
  final List<Widget> children;
  const FormCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) => EduCard(
    radius: 14,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const FieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5, top: 10),
    child: Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Ui.text,
        ),
        children: [
          if (required)
            const TextSpan(text: ' *', style: TextStyle(color: Ui.red)),
        ],
      ),
    ),
  );
}

class EduField extends StatelessWidget {
  final String hint;
  final int maxLines;
  final TextEditingController? controller;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;

  final bool error;

  const EduField({
    super.key,
    this.hint = 'Value',
    this.maxLines = 1,
    this.controller,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = error ? Ui.red : Ui.line;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFB6BFCC)),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor, width: error ? 1.3 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: error ? Ui.red : Ui.blue, width: 1.3),
        ),
      ),
    );
  }
}

class EduSelect extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool error;

  const EduSelect({
    super.key,
    this.hint = 'Value',
    this.items = const [],
    this.value,
    this.onChanged,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = error ? Ui.red : Ui.line;

    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Ui.muted),
      style: const TextStyle(fontSize: 12, color: Ui.text),
      hint: Text(
        hint,
        style: const TextStyle(fontSize: 11, color: Color(0xFFB6BFCC)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged ?? (_) {},
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor, width: error ? 1.3 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: error ? Ui.red : Ui.blue, width: 1.3),
        ),
      ),
    );
  }
}

class StatusRadio extends StatelessWidget {
  final bool active;
  final ValueChanged<bool> onChanged;
  const StatusRadio({super.key, required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _item('Aktif', true),
      const SizedBox(width: 40),
      _item('Nonaktif', false),
    ],
  );

  Widget _item(String label, bool v) => GestureDetector(
    onTap: () => onChanged(v),
    child: Row(
      children: [
        Icon(
          active == v ? Icons.radio_button_checked : Icons.radio_button_off,
          size: 18,
          color: active == v ? Ui.navy : Ui.muted,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

class EduBottomNav extends StatelessWidget {
  final String role;
  final int current;
  const EduBottomNav({super.key, required this.role, required this.current});

  List<_NavItem> get _items => const [
    _NavItem(Icons.home_outlined, 'Home', '/admin/dashboard'),
    _NavItem(Icons.people_outline, 'Pengguna', '/admin/users'),
    _NavItem(Icons.menu_book_outlined, 'Course', '/admin/courses'),
    _NavItem(Icons.settings_outlined, 'Setting', '/admin/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == current) return;
                    Navigator.pushReplacementNamed(context, items[i].route);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: i == current ? Ui.navGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].icon, size: 20, color: Ui.navy),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Ui.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
