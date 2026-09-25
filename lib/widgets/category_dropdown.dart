import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        // Keep the value controlled so the selected provider category stays in sync.
        // ignore: deprecated_member_use
        value: selected,
        isExpanded: true,
        hint: const Text('Select a category'),
        items: items
            .map((name) => DropdownMenuItem(value: name, child: Text(name)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: const Icon(Icons.category_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Category required' : null,
      ),
    );
  }
}
