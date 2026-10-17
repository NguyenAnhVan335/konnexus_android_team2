package com.meta.junior.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.UUID;

/** Thông tin quan hệ và hồ sơ của người được kiểm tra. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record FriendshipStatusDto(
        UUID userId,              // Giữ userId để tương thích response cũ.
        String status,            // Chỉ NONE, PENDING hoặc ACCEPTED.
        UUID friendshipId,
        String message,
        UUID id,                  // ID người được kiểm tra (cùng giá trị với userId).
        String name,
        @JsonProperty("avatar_url") String avatarUrl,
        @JsonProperty("is_online") boolean isOnline,
        String direction) {      // SENT/RECEIVED khi PENDING, null khi NONE/ACCEPTED.
}
