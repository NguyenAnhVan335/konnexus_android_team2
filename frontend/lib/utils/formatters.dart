/// Định dạng ngày giờ và văn bản hiển thị.
library;

String formatRelativeTime(DateTime? time) {
  if (time == null) {
    return '';
  }
  final Duration diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inSeconds < 60) {
    return 'Vừa xong';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} phút trước';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} giờ trước';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} ngày trước';
  }
  return '${_two(time.day)}/${_two(time.month)}/${time.year}';
}

String formatDateTime(DateTime? time) {
  if (time == null) {
    return '—';
  }
  return '${_two(time.hour)}:${_two(time.minute)} ${_two(time.day)}/${_two(time.month)}/${time.year}';
}

String formatDate(DateTime? time) {
  if (time == null) {
    return '—';
  }
  return '${_two(time.day)}/${_two(time.month)}/${time.year}';
}

String formatShortDay(DateTime? time) {
  if (time == null) {
    return '';
  }
  return '${_two(time.day)}/${_two(time.month)}';
}

/// Rút gọn số lượng kiểu 1,2K / 1,3M để hiển thị trên thẻ bài viết.
String formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')}K';
  }
  return value.toString();
}

String initialsOf(String? name) {
  final String value = (name ?? '').trim();
  if (value.isEmpty) {
    return 'K';
  }
  final List<String> words = value.split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }
  return (words.first.substring(0, 1) + words.last.substring(0, 1))
      .toUpperCase();
}

String truncateText(String? value, {int maxLength = 320}) {
  final String text = value ?? '';
  if (text.length <= maxLength) {
    return text;
  }
  return '${text.substring(0, maxLength)}…';
}

String _two(int value) => value.toString().padLeft(2, '0');
