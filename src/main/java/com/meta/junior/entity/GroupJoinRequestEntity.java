package com.meta.junior.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "group_join_requests", uniqueConstraints =
        @UniqueConstraint(name = "uk_group_join_request", columnNames = {"group_id", "user_id"}),
        indexes = @Index(name = "idx_group_join_requests_group_status", columnList = "group_id,status"))
public class GroupJoinRequestEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(name = "group_id", nullable = false)
    public UUID groupId;

    @Column(name = "user_id", nullable = false)
    public UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public GroupJoinStatus status = GroupJoinStatus.PENDING;

    @Column(name = "created_at", nullable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    public LocalDateTime updatedAt;

    @Column(name = "resolved_by")
    public UUID resolvedBy;

    @PrePersist
    void onCreate() { createdAt = updatedAt = LocalDateTime.now(); }

    @PreUpdate
    void onUpdate() { updatedAt = LocalDateTime.now(); }
}
