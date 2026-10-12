package com.meta.junior.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.meta.junior.entity.MediaType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.util.UUID;

/**
 * A media item supplied by the client inside {@code media_list}:
 * {@code { "id": ..., "media_url": ..., "media_type": ..., "display_order": ... }}.
 *
 * <p>{@code id} is accepted for compatibility with the API contract but is always ignored: media ids
 * are generated server-side on persist.</p>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record MediaRequest(
        UUID id,

        @NotBlank(message = "media_url is required")
        @Size(max = 2048, message = "media_url must not exceed 2048 characters")
        String mediaUrl,

        @NotNull(message = "media_type is required")
        MediaType mediaType,

        @NotNull(message = "display_order is required")
        @PositiveOrZero(message = "display_order must be >= 0")
        Integer displayOrder
) {
}
