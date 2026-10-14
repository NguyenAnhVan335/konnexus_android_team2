package com.meta.junior.repository;

import java.util.List;
import java.util.UUID;

import com.meta.junior.entity.Emoji;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class EmojiRepository
        implements PanacheRepositoryBase<Emoji, UUID> {

    public List<Emoji> findByPostId(UUID postId) {
        return find("postId", postId).list();
    }

    public List<Emoji> findByCommentId(UUID cmtId) {
        return find("cmtId", cmtId).list();
    }

    public Emoji findByPostAndAuthor(UUID postId, UUID authorId) {
        return find("postId = ?1 and authorId = ?2", postId, authorId)
                .firstResult();
    }

    public Emoji findByCommentAndAuthor(UUID cmtId, UUID authorId) {
        return find("cmtId = ?1 and authorId = ?2", cmtId, authorId)
                .firstResult();
    }
}