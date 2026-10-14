package com.meta.junior.dto.post;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.meta.junior.common.PostPrivacy;
import com.meta.junior.dto.AuthorResponse;
import com.meta.junior.dto.MediaResponse;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Detail representation of a post returned by {@code GET /api/v1/posts/{id}}.
 *
 * <p>It is a strict superset of {@link PostResponse}: the whole post payload is returned flat
 * (so a client can reuse its list model) plus the interaction information that only makes sense for
 * a single post — the reaction summary and the comments:</p>
 * <pre>
 * {
 *   "id": "...", "author": { ... }, "content": "...", "privacy": "PUBLIC",
 *   "like_count": 2, "comment_count": 1,
 *   "media_list": [ ... ], "created_at": "...", "updated_at": "...",
 *   "edited": false, "_liked": true,
 *   "reactions": { "total": 2, "by_type": { "LIKE": 2 }, "my_reaction": "LIKE" },
 *   "comments": [ { "id": "...", "post_id": "...", "parent_comment_id": null, ... } ]
 * }
 * </pre>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record PostDetailResponse(
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
        @JsonProperty("_liked") boolean liked,
        ReactionSummaryResponse reactions,
        List<CommentResponse> comments
) {
    public static PostDetailResponse from(
            PostResponse post,
            ReactionSummaryResponse reactions,
            List<CommentResponse> comments) {
        return new PostDetailResponse(
                post.id(),
                post.author(),
                post.content(),
                post.privacy(),
                post.likeCount(),
                post.commentCount(),
                post.mediaList(),
                post.createdAt(),
                post.updatedAt(),
                post.edited(),
                post.liked(),
                reactions,
                comments
        );
    }
}
