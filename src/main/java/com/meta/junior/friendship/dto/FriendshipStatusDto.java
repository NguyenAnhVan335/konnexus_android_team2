package com.meta.junior.friendship.dto;

import java.util.UUID;

public record FriendshipStatusDto(
        UUID userId,
        String status,
        UUID friendshipId,
        String message) {
}
