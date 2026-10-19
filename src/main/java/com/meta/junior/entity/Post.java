package com.meta.junior.entity;
import com.meta.junior.common.PostPrivacy;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "posts")
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User author;

    @Column(name = "content", columnDefinition = "TEXT", nullable = false)
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(name = "privacy", nullable = false)
    @Builder.Default
    private PostPrivacy privacy = PostPrivacy.PUBLIC;

    @Column(name = "like_count", nullable = false)
    @Builder.Default
    private int like_count = 0;

    @Column(name = "comment_count", nullable = false)
    @Builder.Default
    private int comment_count = 0;

    @Column(name = "is_edited", nullable = false)
    @Builder.Default
    private boolean is_edited = false;

    @Column(name = "is_deleted", nullable = false)
    @Builder.Default
    private boolean isDeleted = false;

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<PostMedia> mediaList = new ArrayList<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    // Các helper method đảm bảo tương thích ngược mã nguồn cũ
    public boolean is_deleted() {
        return this.isDeleted;
    }

    public void set_deleted(boolean isDeleted) {
        this.isDeleted = isDeleted;
    }

    public LocalDateTime getCreated_at() {
        return this.createdAt;
    }

    public void setCreated_at(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdated_at() {
        return this.updatedAt;
    }

    public void setUpdated_at(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    /**
     * Helper method đồng bộ quan hệ hai chiều giữa Post và PostMedia
     */
    public void addMedia(PostMedia media) {
        mediaList.add(media);
        media.setPost(this);
    }

    public void removeMedia(PostMedia media) {
        mediaList.remove(media);
        media.setPost(null);
    }
}
