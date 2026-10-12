package com.meta.junior.dto.post;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.meta.junior.dto.AuthorResponse;
import com.meta.junior.dto.MediaResponse;
import com.meta.junior.entity.Post;
import com.meta.junior.common.PostPrivacy;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Public representation of a {@link Post}, matching the API contract:
 * <pre>
 * {
 *   "id": "...", "author": { "id": "...", "username": "...", "avatar_url": null },
 *   "content": "...", "privacy": "PUBLIC", "like_count": 0, "comment_count": 0,
 *   "media_list": [ ... ], "created_at": "...", "updated_at": "...",
 *   "edited": false, "_liked": false
 * }
 * </pre>
 * Kept as a DTO so the entity is never serialized directly.
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record PostResponse(
        UUID id,
        AuthorResponse author,
        String content,
        PostPrivacy privacy,
        int likeCount,
        int commentCount,
        List<MediaResponse> mediaList,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        boolean edited,
        @JsonProperty("_liked") boolean liked
) {
    public static PostResponse from(Post post) {
        // TODO (User module): resolve the real username/avatar_url once a User entity exists.
        AuthorResponse author = new AuthorResponse(post.getAuthorId(), null, null);
        List<MediaResponse> media = post.getMediaList().stream()
                .map(MediaResponse::from)
                .toList();
        return new PostResponse(
                post.getId(),
                author,
                post.getContent(),
                post.getPrivacy(),
                post.getLikeCount(),
                post.getCommentCount(),
                media,
                post.getCreatedAt(),
                post.getUpdatedAt(),
                post.isEdited(),
                // TODO (_liked): resolve per-current-user like state once the like feature exists.
                false
        );
    }
}

