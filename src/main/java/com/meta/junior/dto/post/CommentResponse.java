package com.meta.junior.dto.post;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.meta.junior.entity.PostComment;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A comment attached to a post, returned inside {@link PostDetailResponse#comments()}:
 * <pre>
 * {
 *   "id": "...", "post_id": "...", "parent_comment_id": null,
 *   "content": "...", "image": null, "created_at": "..."
 * }
 * </pre>
 *
 * <p>Comments are returned flat (ordered by {@code created_at} ascending); replies carry the id of
 * their parent in {@code parent_comment_id}, so a client can rebuild the thread.</p>
 *
 * <p><strong>Known gap:</strong> the {@code post_comments} table has no author column, so the
 * comment author cannot be resolved yet — adding {@code author_id} belongs to the comment module.</p>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record CommentResponse(
        UUID id,
        UUID postId,
        UUID parentCommentId,
        String content,
        String image,
        LocalDateTime createdAt
) {
    public static CommentResponse from(PostComment comment) {
        return new CommentResponse(
                comment.id,
                comment.postId,
                comment.cmtId,
                comment.content,
                comment.image,
                comment.createdAt
        );
    }
}
