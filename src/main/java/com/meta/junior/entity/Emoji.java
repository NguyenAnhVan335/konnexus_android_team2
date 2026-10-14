
package com.meta.junior.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "emojis")
public class Emoji {

    @Id
    public UUID id;

    @Column(name = "emoji_type", nullable = false)
    public String emojiType;

    @Column(name = "post_id")
    public UUID postId;

    @Column(name = "cmt_id")
    public UUID cmtId;

    @Column(name = "author_id", nullable = false)
    public UUID authorId;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;

    @PrePersist
    public void beforeInsert() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
