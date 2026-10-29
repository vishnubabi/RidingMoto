import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ColorPickerRow extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kColorPresets.map((hex) {
        final isSelected = hex == selected;
        final color = Color(
          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
        );
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withAlpha(153), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
