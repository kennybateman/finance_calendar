import 'package:flutter/material.dart';

class NavigationButton extends StatelessWidget {
    final String label;
    final int index;
    final int selectedIndex;
    final ValueChanged<int> onPressed;
    const NavigationButton(this.label, this.index, this.selectedIndex, this.onPressed, { super.key });
    
    @override
    Widget build(BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;
      final bool isSelected = index == selectedIndex;
      return TextButton(
        onPressed: () => onPressed(index),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          backgroundColor: isSelected ? colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          foregroundColor: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      );
    }
}