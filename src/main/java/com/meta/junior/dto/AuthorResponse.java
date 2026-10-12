package com.meta.junior.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.util.UUID;

/**
 * Public representation of the author of a post:
 * {@code { "id": ..., "username": ..., "avatar_url": ... }}.
 *
 * <p><strong>TODO (User module):</strong> there is no {@code User} entity in the project yet, so
 * {@code username} and {@code avatarUrl} are currently {@code null} placeholders and only {@code id}
 * (the author id) is populated. Once the User module exists, resolve these fields from it.</p>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record AuthorResponse(
        UUID id,
        String username,
        String avatarUrl
) {
}
