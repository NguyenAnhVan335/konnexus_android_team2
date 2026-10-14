package com.meta.junior.friendship.dto;

import com.meta.junior.friendship.entity.FriendshipEntity;
import java.util.UUID;

public record FriendshipDto(
        UUID id,
        UUID senderId,
        UUID receiverId,
        String status,
        String statusLabel) {
    public static FriendshipDto from(FriendshipEntity friendship) {
        String label = switch (friendship.getStatus()) {
            case FriendshipEntity.PENDING -> "Đang chờ";
            case FriendshipEntity.ACCEPTED -> "Đã chấp nhận";
            default -> friendship.getStatus();
        };

        return new FriendshipDto(
                friendship.getId(),
                friendship.getSenderId(),
                friendship.getReceiverId(),
                friendship.getStatus(),
                label);
    }
}
