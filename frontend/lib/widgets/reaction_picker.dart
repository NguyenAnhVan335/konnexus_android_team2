import 'package:flutter/material.dart';

/// Một lựa chọn cảm xúc. `type` là `emojiType` gửi lên backend.
class ReactionOption {
  const ReactionOption(this.type, this.emoji, this.label);

  final String type;
  final String emoji;
  final String label;
}

const List<ReactionOption> kReactionOptions = <ReactionOption>[
  ReactionOption('LIKE', '👍', 'Thích'),
  ReactionOption('LOVE', '❤️', 'Yêu thích'),
  ReactionOption('HAHA', '😆', 'Haha'),
  ReactionOption('WOW', '😮', 'Wow'),
  ReactionOption('SAD', '😢', 'Buồn'),
  ReactionOption('ANGRY', '😡', 'Phẫn nộ'),
];

String reactionEmoji(String? type) {
  for (final ReactionOption option in kReactionOptions) {
    if (option.type == type) {
      return option.emoji;
    }
  }
  return '👍';
}

String reactionLabel(String? type) {
  for (final ReactionOption option in kReactionOptions) {
    if (option.type == type) {
      return option.label;
    }
  }
  return 'Cảm xúc';
}

/// Thanh cảm xúc nổi (floating) dạng hàng ngang, chỉ hiện emoji — giống Facebook.
Future<String?> showReactionPicker(BuildContext context,
    {String? currentType}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chọn cảm xúc',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withAlpha(70),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final ReactionOption option in kReactionOptions)
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context).pop(option.type),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      child: Text(option.emoji,
                          style: const TextStyle(fontSize: 30)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
