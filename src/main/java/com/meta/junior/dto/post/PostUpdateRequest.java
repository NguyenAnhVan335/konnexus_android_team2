package com.meta.junior.dto.post;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.meta.junior.dto.MediaRequest;
import com.meta.junior.common.PostPrivacy;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Payload for updating a post:
 * <pre>
 * {
 *   "content": "...",
 *   "privacy": "PUBLIC",
 *   "media_list": [ { "media_url": "...", "media_type": "IMAGE", "display_order": 0 } ]
 * }
 * </pre>
 *
 * <p>Only {@code content}, {@code privacy} and {@code mediaList} are mutable. When {@code mediaList}
 * is provided the whole list is replaced. {@code id}, {@code author}, {@code like_count},
 * {@code comment_count} and {@code created_at} are immutable and ignored by the update operation.
 * {@code status} (soft delete flag) is never set by the client.</p>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record PostUpdateRequest(
        @Size(max = 5000, message = "content must not exceed 5000 characters")
        String content,

        @NotNull(message = "privacy is required")
        PostPrivacy privacy,

        @Size(max = 10, message = "media_list must contain at most 10 items")
        List<@Valid MediaRequest> mediaList
) {
}

