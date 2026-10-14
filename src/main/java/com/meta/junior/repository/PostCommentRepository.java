
package com.meta.junior.repository;

import java.util.List;
import java.util.UUID;

import com.meta.junior.entity.PostComment;

import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class PostCommentRepository
        implements PanacheRepositoryBase<PostComment, UUID> {

    public List<PostComment> findByPostId(UUID postId) {
        return find("postId", postId).list();
    }

    public List<PostComment> findByParentCommentId(UUID cmtId) {
        return find("cmtId", cmtId).list();
    }
}
