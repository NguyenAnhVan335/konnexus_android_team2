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
 * Payload for creating a post:
 * <pre>
 * {
 *   "content": "...",
 *   "privacy": "PUBLIC",
 *   "media_list": [ { "id": "...", "media_url": "...", "media_type": "IMAGE", "display_order": 0 } ]
 * }
 * </pre>
 *
 * <p>At least one of {@code content} or {@code mediaList} must be present; this cross-field rule is
 * enforced in the service layer. At most 10 media items are allowed. The author is never accepted
 * from the client — it is resolved from the authenticated user.</p>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record PostCreateRequest(
        @Size(max = 5000, message = "content must not exceed 5000 characters")
        String content,

        @NotNull(message = "privacy is required")
        PostPrivacy privacy,

        @Size(max = 10, message = "media_list must contain at most 10 items")
        List<@Valid MediaRequest> mediaList
) {
}

