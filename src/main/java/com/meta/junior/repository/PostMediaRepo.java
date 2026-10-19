package com.meta.junior.repository;

import com.meta.junior.entity.PostMedia;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class PostMediaRepo implements PanacheRepositoryBase<PostMedia, UUID> {

    /**
     * Lấy danh sách toàn bộ media của danh sách postIds (Batch Fetch),
     * sắp xếp theo display_order tăng dần
     * @param postIds Danh sách ID bài viết
     * @return Danh sách PostMedia thuộc các bài viết này
     */
    public List<PostMedia> findByPostIds(List<UUID> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return Collections.emptyList();
        }
        return find("""
                post.id in :postIds
                order by display_order asc
                """,
                Map.of("postIds", postIds)
        ).list();
    }

    /**
     * Lấy toàn bộ tệp media của một bài viết theo thứ tự hiển thị
     */
    public List<PostMedia> findByPostId(UUID postId) {
        return list("post.id = ?1 order by display_order asc", postId);
    }

    /**
     * Xóa toàn bộ media của một bài viết
     */
    public long deleteByPostId(UUID postId) {
        return delete("post.id = ?1", postId);
    }
}
