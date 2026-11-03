package com.meta.junior.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "konnexus_groups")
public class GroupEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(nullable = false, length = 120)
    public String name;

    @Column(columnDefinition = "TEXT")
    public String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public GroupPrivacy privacy = GroupPrivacy.PUBLIC;

    @Column(name = "owner_id", nullable = false)
    public UUID ownerId;

    @Column(name = "cover_url", length = 1024)
    public String coverUrl;

    @Column(name = "require_post_approval", nullable = false)
    public boolean requirePostApproval;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    public LocalDateTime updatedAt;

    @Column(name = "deleted_at")
    public LocalDateTime deletedAt;

    @Column(name = "deleted_by")
    public UUID deletedBy;

    @PrePersist
    void onCreate() {
        createdAt = updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
