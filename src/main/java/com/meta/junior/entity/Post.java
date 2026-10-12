package com.meta.junior.entity;

import com.meta.junior.common.PostPrivacy;
import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * A social network post.
 *
 * <p>{@code authorId} is intentionally stored as a plain {@link UUID} reference to the
 * {@code User.id} column. There is currently no {@code User} JPA entity in the project, so no
 * {@code @ManyToOne} relationship is used — mirroring the "store the UUID directly" style that
 * keeps the Post feature decoupled from the (not yet implemented) User/authentication module.</p>
 *
 * <p>A post owns zero or more {@link PostMedia} items ({@code media_list}). The collection is
 * cascaded and orphan-removal is enabled so media is managed together with the post.</p>
 */
@Entity
@Table(name = "post")
@Getter
@Setter
@NoArgsConstructor
public class Post extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "content", length = 5000)
    private String content;

    @Column(name = "author_id", nullable = false, updatable = false)
    private UUID authorId;

    @Enumerated(EnumType.STRING)
    @Column(name = "privacy", nullable = false, length = 20)
    private PostPrivacy privacy = PostPrivacy.PUBLIC;

    /**
     * Denormalised counter maintained by the (future) like feature. Always {@code >= 0}.
     */
    @Column(name = "like_count", nullable = false)
    private int likeCount = 0;

    /**
     * Denormalised counter maintained by the (future) comment feature. Always {@code >= 0}.
     */
    @Column(name = "comment_count", nullable = false)
    private int commentCount = 0;

    /**
     * {@code true} once the post has been updated at least once after creation.
     */
    @Column(name = "edited", nullable = false)
    private boolean edited = false;

    @Column(name = "status", nullable = false)
    private Boolean status = Boolean.TRUE;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("displayOrder ASC")
    private List<PostMedia> mediaList = new ArrayList<>();

    /**
     * Adds a media item to this post, keeping both sides of the association in sync.
     */
    public void addMedia(PostMedia media) {
        media.setPost(this);
        this.mediaList.add(media);
    }

    /**
     * Removes all media items. Orphan removal deletes the rows on flush.
     */
    public void clearMedia() {
        this.mediaList.clear();
    }

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
        if (status == null) {
            status = Boolean.TRUE;
        }
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

