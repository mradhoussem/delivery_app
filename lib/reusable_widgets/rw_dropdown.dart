import 'package:flutter/material.dart';

class RwDropdown extends StatelessWidget {
  const RwDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
    this.hint,
    this.label,
    this.prefixIcon,
    this.iconColor,
    this.bordercolor = Colors.black26,
    this.focusColor = const Color(0xFF96C8E3),
    this.backgroundColor = Colors.white,
    this.validator,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String)? itemLabelBuilder; // Pour transformer le nom technique en label
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final Color? iconColor;
  final Color bordercolor;
  final Color focusColor;
  final Color backgroundColor;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    // Sécurité pour éviter le crash si la valeur n'est pas dans la liste
    final String? safeValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          validator: validator,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          dropdownColor: backgroundColor,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: iconColor)
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: bordercolor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: focusColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(itemLabelBuilder != null ? itemLabelBuilder!(item) : item),
            );
          }).toList(),
        ),
      ],
    );
  }
}