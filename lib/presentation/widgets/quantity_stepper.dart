import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final double value;
  final double step;
  final double min;
  final double? max;
  final ValueChanged<double> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    this.step = 1.0,
    this.min = 0.0,
    this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value - step < min
              ? null
              : () => onChanged(value - step),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 56),
          alignment: Alignment.center,
          child: Text(
            value % 1 == 0
                ? value.toInt().toString()
                : value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: max != null && value + step > max!
              ? null
              : () => onChanged(value + step),
        ),
      ],
    );
  }
}
