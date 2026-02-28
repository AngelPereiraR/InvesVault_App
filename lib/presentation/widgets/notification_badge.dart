import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: count > 0 ? Text('$count') : null,
      isLabelVisible: count > 0,
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: onTap,
        tooltip: 'Notificaciones',
      ),
    );
  }
}
