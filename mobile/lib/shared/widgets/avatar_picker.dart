import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class AvatarPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kAvatars.map((avatar) {
        final isSelected = avatar['id'] == selected;
        return GestureDetector(
          onTap: () => onChanged(avatar['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentDim : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(avatar['emoji']!, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 4),
                Text(
                  avatar['label']!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
