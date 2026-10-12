package com.meta.junior.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.meta.junior.dto.post.PostResponse;
import com.meta.junior.entity.MediaType;
import com.meta.junior.entity.PostMedia;

import java.util.UUID;

/**
 * A media item returned inside {@link PostResponse#mediaList()}:
 * {@code { "id": ..., "media_url": ..., "media_type": ..., "display_order": ... }}.
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record MediaResponse(
        UUID id,
        String mediaUrl,
        MediaType mediaType,
        int displayOrder
) {
    public static MediaResponse from(PostMedia media) {
        return new MediaResponse(
                media.getId(),
                media.getMediaUrl(),
                media.getMediaType(),
                media.getDisplayOrder()
        );
    }
}
