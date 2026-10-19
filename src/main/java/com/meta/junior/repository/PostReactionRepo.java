package com.meta.junior.repository;

import com.meta.junior.entity.PostReaction;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class PostReactionRepo implements PanacheRepositoryBase<PostReaction, UUID> {

    public Optional<PostReaction> findByPostAndUser(UUID postId, UUID userId) {
        return find("post.id = ?1 and author.id = ?2", postId, userId).firstResultOptional();
    }

    /**Lấy danh sách các reaction của bài viết (phân trang)*/
    public PanacheQuery<PostReaction> findByPostId(UUID postId, Page pageable) {
        return find("post.id = ?1 order by createdAt desc", postId).page(pageable);
    }
}