import 'package:flutter/material.dart';

import '../../../models/chat_model.dart';
import '../../../theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.isMine;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background = isMine
        ? Theme.of(context).colorScheme.primary
        : (isDark ? AppColors.darkSurface : AppColors.surfaceMuted);
    final Color foreground = isMine
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
          border:
              isMine ? null : Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message.text,
              style: TextStyle(fontSize: 13.5, height: 1.35, color: foreground),
            ),
            const SizedBox(height: 3),
            Text(
              _timeOnly(message.sentAt),
              style: TextStyle(
                fontSize: 9.5,
                color: isMine ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeOnly(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
