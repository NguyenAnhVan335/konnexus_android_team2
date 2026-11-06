package com.meta.junior.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "group_posts", indexes =
        @Index(name = "idx_group_posts_group_status", columnList = "group_id,status,deleted_at"))
public class GroupPostEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(name = "group_id", nullable = false)
    public UUID groupId;

    @Column(name = "author_id", nullable = false)
    public UUID authorId;

    @Column(columnDefinition = "TEXT", nullable = false)
    public String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public GroupPostStatus status = GroupPostStatus.PUBLISHED;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    public LocalDateTime updatedAt;

    @Column(name = "moderated_by")
    public UUID moderatedBy;

    @Column(name = "moderated_at")
    public LocalDateTime moderatedAt;

    @Column(name = "deleted_at")
    public LocalDateTime deletedAt;

    @PrePersist
    void onCreate() { createdAt = updatedAt = LocalDateTime.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = LocalDateTime.now(); }
}
