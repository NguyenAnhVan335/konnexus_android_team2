package com.meta.junior.repository;

import com.meta.junior.entity.PostComment;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class PostCommentRepo implements PanacheRepositoryBase<PostComment, UUID> {

    public Optional<PostComment> findActiveById(UUID id) {
        return find("id = ?1 and isDeleted = false", id).firstResultOptional();
    }

    public PanacheQuery<PostComment> findByPostId(UUID postId, Page page) {
        return find("select distinct c from PostComment c left join fetch c.author where c.post.id = ?1 and c.isDeleted = false order by c.createdAt desc", postId)
                .page(page);
    }
}