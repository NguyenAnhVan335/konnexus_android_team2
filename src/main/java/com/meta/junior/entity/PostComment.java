
package com.meta.junior.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "post_comments")
public class PostComment {

    @Id
    public UUID id;

    @Column(name = "post_id", nullable = false)
    public UUID postId;

    @Column(nullable = false, columnDefinition = "TEXT")
    public String content;

    @Column(name = "image", columnDefinition = "TEXT")
    public String image;

    // ID bình luận cha, null nếu là bình luận gốc
    @Column(name = "cmt_id")
    public UUID cmtId;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;

    @Column(nullable = false)
    public boolean status = true;

    @PrePersist
    public void beforeInsert() {
        if (id == null) {
            id = UUID.randomUUID();
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    public void beforeUpdate() {
        // Không thay đổi createdAt khi cập nhật bình luận
    }
}
