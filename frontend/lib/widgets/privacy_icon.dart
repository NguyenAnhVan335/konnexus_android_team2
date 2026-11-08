import 'package:flutter/material.dart';

import '../models/post_model.dart';

/// Icon tương ứng mức riêng tư của bài viết.
IconData privacyIcon(PostPrivacy privacy) {
  switch (privacy) {
    case PostPrivacy.private:
      return Icons.lock_outline;
    case PostPrivacy.friends:
      return Icons.group_outlined;
    case PostPrivacy.public:
      return Icons.public;
  }
}
