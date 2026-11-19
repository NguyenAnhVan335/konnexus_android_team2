package com.meta.junior.common;

/**
 * Loại hoạt động được ghi vào lịch sử hoạt động của người dùng.
 */
public enum ActivityType {
    /** Người dùng bày tỏ cảm xúc với bài viết. */
    REACTION,
    /** Người dùng bình luận bài viết. */
    COMMENT,
    /** Người dùng tạo bài viết. */
    POST,
    /** Người dùng gửi lời mời kết bạn. */
    FRIEND_REQUEST
}
