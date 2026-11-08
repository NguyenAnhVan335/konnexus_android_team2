package com.meta.junior.repository;

import com.meta.junior.common.ReactionType;
import com.meta.junior.entity.PostReaction;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@ApplicationScoped
public class PostReactionRepo implements PanacheRepositoryBase<PostReaction, UUID> {

    public Optional<PostReaction> findByPostAndUser(UUID postId, UUID userId) {
        return find("post.id = ?1 and author.id = ?2", postId, userId).firstResultOptional();
    }

    /**Lấy danh sách các reaction của bài viết (phân trang)*/
    public PanacheQuery<PostReaction> findByPostId(UUID postId, Page pageable) {
        return find("post.id = ?1 order by createdAt desc", postId).page(pageable);
    }

    public Optional<PostReaction> findByCommentAndUser(UUID commentId, UUID userId) {
        return find("comment.id = ?1 and author.id = ?2", commentId, userId).firstResultOptional();
    }

    /**Lấy danh sách các reaction của bình luận (phân trang)*/
    public PanacheQuery<PostReaction> findByCommentId(UUID commentId, Page pageable) {
        return find("comment.id = ?1 order by createdAt desc", commentId).page(pageable);
    }

    /**Đếm số reaction của một bình luận.*/
    public long countByCommentId(UUID commentId) {
        return count("comment.id = ?1", commentId);
    }

    /**Lấy tập hợp postId mà user đã reaction (batch, tránh N+1).*/
    public Set<UUID> findReactedPostIds(UUID userId, List<UUID> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return Set.of();
        }
        return find("author.id = ?1 and post.id in ?2", userId, postIds)
                .list()
                .stream()
                .map(r -> r.getPost().getId())
                .collect(Collectors.toSet());
    }

    /**Lấy map postId -> loại cảm xúc mà user đã thả (batch, tránh N+1).*/
    public Map<UUID, ReactionType> findReactedTypes(UUID userId, List<UUID> postIds) {
        if (postIds == null || postIds.isEmpty()) {
            return Map.of();
        }
        return find("author.id = ?1 and post.id in ?2", userId, postIds)
                .list()
                .stream()
                .collect(Collectors.toMap(
                        r -> r.getPost().getId(),
                        PostReaction::getType,
                        (a, b) -> a));
    }
}