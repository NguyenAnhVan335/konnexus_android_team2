package com.meta.junior.service;



import com.meta.junior.dto.social_media.hashtag.HashtagResponseDTO;
import com.meta.junior.entity.Post;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

public interface HashtagService {

    /**
     * Lấy danh sách tên hashtag của nhiều bài viết cùng lúc (Batch Fetch)
     * @param postIds Danh sách ID bài viết
     * @return Map gom nhóm: Key là postId, Value là danh sách tên hashtag
     */
    Map<UUID, List<String>> getHashtagNamesByPostIds(List<UUID> postIds);

    /**
     * Bóc tách tập hợp các hashtag duy nhất từ nội dung văn bản
     */
    Set<String> extractHashtags(String content);

    /**
     * Đồng bộ hóa danh sách hashtag của bài viết:
     * - Tự động tạo hashtag mới nếu chưa có trong DB.
     * - Tăng usage_count cho hashtag mới được gán.
     * - Giảm usage_count và xóa liên kết đối với các hashtag bị gỡ bỏ.
     */
    void syncPostHashtags(Post post, String content);

    /**
     * Xóa sạch liên kết hashtag của bài viết và giảm usage_count tương ứng (dùng khi xóa bài)
     */
    void removePostHashtags(UUID postId);

    /**
     * Lấy danh sách tên các hashtag thuộc về một bài viết cụ thể
     */
    List<String> getHashtagNamesByPostId(UUID postId);

    /**
     * Lấy danh sách Top Hashtags thịnh hành nhất hệ thống
     */
    List<HashtagResponseDTO> getTrendingHashtags(int limit);

    /**
     * Tìm kiếm gợi ý hashtag theo tiền tố tên (autocomplete)
     */
    List<HashtagResponseDTO> searchHashtags(String query, int limit);
}
