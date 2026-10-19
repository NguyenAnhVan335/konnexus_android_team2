package com.meta.junior.repository;

import com.meta.junior.entity.Hashtag;
import com.meta.junior.entity.PostHashtag;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class PostHashtagRepo implements PanacheRepositoryBase<PostHashtag, UUID> {

    /**
     * Lấy danh sách liên kết PostHashtag kèm eager nạp Hashtag theo danh sách postIds (Batch Fetch)
     * @param postIds Danh sách ID bài viết trong trang hiện tại
     * @return Danh sách các bản ghi PostHashtag đã fetch sẵn đối tượng Hashtag
     */
    public List<PostHashtag> findByPostIdsWithHashtag(List<UUID> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return Collections.emptyList();
        }
        return find("""
                select ph
                from PostHashtag ph
                join fetch ph.hashtag
                where ph.post.id in :postIds
                """,
                Map.of("postIds", postIds)
        ).list();
    }

    /**
     * Lấy danh sách liên kết theo bài viết
     */
    public List<PostHashtag> findByPostId(UUID postId) {
        return find("post.id = ?1", postId).list();
    }

    /**
     * Lấy danh sách đối tượng Hashtag được gắn vào một bài viết
     */
    public List<Hashtag> findHashtagsByPostId(UUID postId) {
        return find("select ph.hashtag from PostHashtag ph where ph.post.id = ?1", postId)
                .project(Hashtag.class)
                .list();
    }

    /**
     * Kiểm tra cặp (post_id, hashtag_id) đã tồn tại hay chưa
     */
    public boolean exists(UUID postId, UUID hashtagId) {
        return count("post.id = ?1 and hashtag.id = ?2", postId, hashtagId) > 0;
    }

    /**
     * Xóa toàn bộ liên kết hashtag của một bài viết (dùng khi cập nhật hoặc xóa bài viết)
     */
    public long deleteByPostId(UUID postId) {
        return delete("post.id = ?1", postId);
    }

    /**
     * Đếm số lượng bài viết còn liên kết với một hashtag
     */
    public long countByHashtagId(UUID hashtagId) {
        return count("hashtag.id = ?1", hashtagId);
    }
}
