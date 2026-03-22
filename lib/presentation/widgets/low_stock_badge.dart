import 'package:flutter/material.dart';

class LowStockBadge extends StatelessWidget {
  final int count;
  const LowStockBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 14, color: Theme.of(context).colorScheme.onError),
          const SizedBox(width: 4),
          Text(
            '$count bajo mínimo',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onError,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
