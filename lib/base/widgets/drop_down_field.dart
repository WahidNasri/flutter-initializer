import 'package:flutter/material.dart';

class DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String? hint;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final String Function(T)? labelBuilder;
  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: value,
          hint: hint != null ? Text(hint!) : null,
          validator: validator,
          items:
              items
                  .map(
                    (e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        labelBuilder != null
                            ? labelBuilder!.call(e)
                            : e.toString(),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
