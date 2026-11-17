import 'package:flutter/material.dart';

import '../ui/kit.dart';

typedef StudentFilterApplyCallback =
    void Function(
      String? selectedClass,
      String? selectedMajor,
      String sortOrder,
    );

class StudentFilterPanel extends StatefulWidget {
  const StudentFilterPanel({
    super.key,
    required this.classOptions,
    required this.majorOptions,
    required this.selectedClass,
    required this.selectedMajor,
    required this.sortOrder,
    required this.onApply,
  });

  final List<String> classOptions;
  final List<String> majorOptions;
  final String? selectedClass;
  final String? selectedMajor;
  final String sortOrder;
  final StudentFilterApplyCallback onApply;

  @override
  State<StudentFilterPanel> createState() => _StudentFilterPanelState();
}

class _StudentFilterPanelState extends State<StudentFilterPanel> {
  bool _expanded = false;
  late String? _selectedClass;
  late String? _selectedMajor;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.selectedClass;
    _selectedMajor = widget.selectedMajor;
    _sortOrder = widget.sortOrder;
  }

  @override
  void didUpdateWidget(covariant StudentFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedClass != widget.selectedClass ||
        oldWidget.selectedMajor != widget.selectedMajor ||
        oldWidget.sortOrder != widget.sortOrder) {
      _selectedClass = widget.selectedClass;
      _selectedMajor = widget.selectedMajor;
      _sortOrder = widget.sortOrder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Colors.white,
              foregroundColor: Ui.text,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Ui.line),
              ),
            ),
            icon: Icon(
              _expanded ? Icons.filter_alt_off : Icons.filter_alt,
              size: 18,
            ),
            label: Text(_expanded ? 'Tutup Filter' : 'Filter'),
          ),
        ),
        if (_expanded)
          Container(
            key: const ValueKey('student-filter-panel-content'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Ui.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter siswa',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _sectionTitle('Kelas'),
                const SizedBox(height: 8),
                _choiceWrap(
                  widget.classOptions,
                  _selectedClass,
                  (value) => setState(() => _selectedClass = value),
                ),
                const SizedBox(height: 16),
                _sectionTitle('Jurusan'),
                const SizedBox(height: 8),
                _choiceWrap(
                  widget.majorOptions,
                  _selectedMajor,
                  (value) => setState(() => _selectedMajor = value),
                ),
                const SizedBox(height: 16),
                _sectionTitle('Urutkan berdasarkan'),
                const SizedBox(height: 8),
                _choiceWrap(
                  const ['A-Z', 'Z-A'],
                  _sortOrder,
                  (value) => setState(() => _sortOrder = value ?? 'A-Z'),
                  singleSelect: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedClass = null;
                            _selectedMajor = null;
                            _sortOrder = 'A-Z';
                          });
                          widget.onApply(null, null, 'A-Z');
                          setState(() => _expanded = false);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          widget.onApply(
                            _selectedClass,
                            _selectedMajor,
                            _sortOrder,
                          );
                          setState(() => _expanded = false);
                        },
                        child: const Text('Atur Filter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
  );

  Widget _choiceWrap(
    List<String> items,
    String? selected,
    ValueChanged<String?> onChanged, {
    bool singleSelect = false,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onChanged(item),
          showCheckmark: false,
          selectedColor: Ui.blue.withValues(alpha: 0.12),
          labelStyle: TextStyle(
            color: isSelected ? Ui.blue : Ui.text,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}
