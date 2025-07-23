
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const DatePickerField({super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              value != null ? DateFormat('yyyy/MM/dd').format(value!) : label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
