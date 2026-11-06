package com.meta.junior.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.meta.junior.entity.FriendshipEntity;
import java.util.UUID;

/**
 * DTO dùng chung cho Friendship.
 * - GET danh sách bạn bè: id là UUID người bạn; name/avatar_url/is_online ở cấp ngoài.
 * - GET lời mời: id là UUID bản ghi Friendship, thông tin người gửi/nhận nằm trong sender/receiver.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record FriendshipDto(
        UUID id,
        UUID senderId,
        UUID receiverId,
        String status,
        String statusLabel,
        String name,
        @JsonProperty("avatar_url") String avatarUrl,
        @JsonProperty("is_online") Boolean isOnline,
        UserInfo sender,
        UserInfo receiver) {

    /** Không tạo FriendDto mới: dùng record lồng để trả 4 trường thông tin người dùng. */
    public record UserInfo(
            UUID id,
            String name,
            @JsonProperty("avatar_url") String avatarUrl,
            @JsonProperty("is_online") boolean isOnline) {
    }

    /** Giữ cấu trúc response cũ cho POST gửi lời mời và PUT chấp nhận. */
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
                label,
                null, null, null, null, null);
    }

    /** GET /api/friends: đủ id, name, avatar_url và is_online của người bạn. */
    public static FriendshipDto fromFriend(UserInfo friend) {
        return new FriendshipDto(
                friend.id(),
                null, null, null, null,
                friend.name(), friend.avatarUrl(), friend.isOnline(),
                null, null);
    }

    /** Trong data.received của GET /api/friends/requests: người gửi có đầy đủ bốn trường. */
    public static FriendshipDto fromReceived(FriendshipEntity friendship, UserInfo sender) {
        FriendshipDto base = from(friendship);
        return new FriendshipDto(
                base.id(), base.senderId(), base.receiverId(),
                base.status(), base.statusLabel(),
                null, null, null,
                sender, null);
    }

    /** Trong data.sent của GET /api/friends/requests: người nhận có đầy đủ bốn trường. */
    public static FriendshipDto fromSent(FriendshipEntity friendship, UserInfo receiver) {
        FriendshipDto base = from(friendship);
        return new FriendshipDto(
                base.id(), base.senderId(), base.receiverId(),
                base.status(), base.statusLabel(),
                null, null, null,
                null, receiver);
    }
    /** Hai danh sách lời mời gộp trong response GET /api/friends/requests. */
    public record RequestLists(
            java.util.List<FriendshipDto> sent,
            java.util.List<FriendshipDto> received) {
    }

}
