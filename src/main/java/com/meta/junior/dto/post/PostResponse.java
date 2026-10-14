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
 *
 * <p>{@code like_count} and {@code comment_count} are the <em>real</em> interaction totals read from
 * the {@code emojis} / {@code post_comments} tables (the denormalised {@code post.like_count} /
 * {@code post.comment_count} columns are not maintained by any feature yet), and {@code _liked} tells
 * whether the current viewer reacted to the post.</p>
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
    public static PostResponse from(
            Post post,
            AuthorResponse author,
            int likeCount,
            int commentCount,
            boolean liked) {
        List<MediaResponse> media = post.getMediaList().stream()
                .map(MediaResponse::from)
                .toList();
        return new PostResponse(
                post.getId(),
                author,
                post.getContent(),
                post.getPrivacy(),
                likeCount,
                commentCount,
                media,
                post.getCreatedAt(),
                post.getUpdatedAt(),
                post.isEdited(),
                liked
        );
    }
}

