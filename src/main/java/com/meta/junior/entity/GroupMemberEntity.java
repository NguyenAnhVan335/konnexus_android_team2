package com.meta.junior.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "group_members", uniqueConstraints =
        @UniqueConstraint(name = "uk_group_member", columnNames = {"group_id", "user_id"}),
        indexes = @Index(name = "idx_group_members_user", columnList = "user_id"))
public class GroupMemberEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    public UUID id;

    @Column(name = "group_id", nullable = false)
    public UUID groupId;

    @Column(name = "user_id", nullable = false)
    public UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public GroupRole role = GroupRole.MEMBER;

    @Column(name = "joined_at", nullable = false)
    public LocalDateTime joinedAt;

    @PrePersist
    void onCreate() { joinedAt = LocalDateTime.now(); }
}
