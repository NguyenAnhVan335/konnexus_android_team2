package com.meta.junior.service;

import com.meta.junior.dto.FriendshipDto;
import com.meta.junior.dto.FriendshipStatusDto;
import com.meta.junior.entity.FriendshipEntity;
import com.meta.junior.exception.ApiException;
import com.meta.junior.repository.FriendshipRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class FriendshipService {

    @Inject
    FriendshipRepository friendshipRepository;
    // Du lieu nguoi dung co san de test Friendship khi module User chua duoc tich hop.
    // Chi la profile gia lap; status ket ban van luu trong database.
    // Danh sach nay khong bi mat khi khoi dong lai Quarkus.
    private static final String TEST_AVATAR_URL =
            "https://api.dicebear.com/9.x/initials/svg?seed=User";

    private record TestUserProfile(String name, String avatarUrl, boolean isOnline) {
    }

    private static final Map<UUID, TestUserProfile> TEST_USER_PROFILES = Map.ofEntries(
            // UUID don gian de nhap truc tiep vao Swagger/Postman.
            Map.entry(UUID.fromString("11111111-1111-1111-1111-111111111111"),
                    new TestUserProfile("Nguyễn Văn A", "https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanA", true)),
            Map.entry(UUID.fromString("22222222-2222-2222-2222-222222222222"),
                    new TestUserProfile("Trần Thị B", "https://api.dicebear.com/9.x/initials/svg?seed=TranThiB", true)),
            Map.entry(UUID.fromString("33333333-3333-3333-3333-333333333333"),
                    new TestUserProfile("Lê Văn C", "https://api.dicebear.com/9.x/initials/svg?seed=LeVanC", false)),
            Map.entry(UUID.fromString("44444444-4444-4444-4444-444444444444"),
                    new TestUserProfile("Phạm Thị D", "https://api.dicebear.com/9.x/initials/svg?seed=PhamThiD", true)),
            // UUID co dinh duoc su dung trong FriendshipGetProfilesTest.
            Map.entry(UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"),
                    new TestUserProfile("Nguyễn Văn A", "https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanA", false)),
            Map.entry(UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
                    new TestUserProfile("Nguyễn Văn B", "https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanB", true)),
            Map.entry(UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc"),
                    new TestUserProfile("Nguyễn Văn C", "https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanC", false)),
            Map.entry(UUID.fromString("dddddddd-dddd-dddd-dddd-dddddddddddd"),
                    new TestUserProfile("Nguyễn Văn D", "https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanD", true))
    );

    // @Inject
    // UserAccountLookupService userAccountLookupService;

    @Transactional
    public FriendshipActionResult sendRequest(UUID senderId, UUID receiverId) {
        validateDifferentUsers(senderId, receiverId);
        // ensureAccountExists(senderId);
        // ensureAccountExists(receiverId);

        var existingOptional = friendshipRepository.findBetween(senderId, receiverId);
        if (existingOptional.isPresent()) {
            FriendshipEntity existing = existingOptional.get();

            if (FriendshipEntity.ACCEPTED.equals(existing.getStatus())) {
                throw new ApiException(409, "Hai người đã là bạn bè");
            }

            if (FriendshipEntity.PENDING.equals(existing.getStatus())) {
                if (senderId.equals(existing.getSenderId())) {
                    // Idempotent behavior: do not create a duplicate pending request.
                    return new FriendshipActionResult(
                            "Đã gửi lời mời", FriendshipDto.from(existing));
                }
                throw new ApiException(409, "Bạn đã nhận lời mời kết bạn từ người dùng này");
            }
        }

        FriendshipEntity friendship = new FriendshipEntity();
        friendship.setSenderId(senderId);
        friendship.setReceiverId(receiverId);
        friendship.setStatus(FriendshipEntity.PENDING);
        friendshipRepository.persistAndFlush(friendship);
        return new FriendshipActionResult(
                "Gửi lời mời kết bạn thành công", FriendshipDto.from(friendship));
    }

    @Transactional
    public FriendshipDto acceptRequest(UUID receiverId, UUID requestId) {
        FriendshipEntity request = getPendingRequestForUpdate(requestId);

        if (!receiverId.equals(request.getReceiverId())) {
            throw new ApiException(403, "Bạn không có quyền xác nhận lời mời kết bạn này");
        }

        request.setStatus(FriendshipEntity.ACCEPTED);
        friendshipRepository.flush();
        return FriendshipDto.from(request);
    }

    @Transactional
    public void rejectRequest(UUID receiverId, UUID requestId) {
        FriendshipEntity request = getPendingRequestForUpdate(requestId);

        if (!receiverId.equals(request.getReceiverId())) {
            throw new ApiException(403, "Bạn không có quyền xóa lời mời kết bạn này");
        }

        // The specification allows removing the request instead of retaining a REJECTED
        // row.
        friendshipRepository.delete(request);
        friendshipRepository.flush();
    }

    @Transactional
    public void cancelRequest(UUID senderId, UUID requestId) {
        FriendshipEntity request = getPendingRequestForUpdate(requestId);

        if (!senderId.equals(request.getSenderId())) {
            throw new ApiException(403, "Bạn không có quyền hủy lời mời kết bạn này");
        }

        friendshipRepository.delete(request);
        friendshipRepository.flush();
    }

    @Transactional
    public void unfriend(UUID currentUserId, UUID friendId) {
        validateDifferentUsers(currentUserId, friendId);
        FriendshipEntity friendship = friendshipRepository.findBetween(currentUserId, friendId)
                .filter(item -> FriendshipEntity.ACCEPTED.equals(item.getStatus()))
                .orElseThrow(() -> new ApiException(404, "Mối quan hệ bạn bè không còn tồn tại"));

        friendshipRepository.delete(friendship);
        friendshipRepository.flush();
    }

    // Lấy thông tin profile giả lập theo UUID. Mọi GET Friendship dùng chung hàm này.
    // Khi nhóm đã có module User, chỉ cần thay thế nguồn dữ liệu tại đây.
    private FriendshipDto.UserInfo getTestUserInfo(UUID userId) {
        TestUserProfile profile = TEST_USER_PROFILES.get(userId);
        String name = profile == null
                ? "Người dùng " + userId.toString().substring(0, 8)
                : profile.name();
        String avatarUrl = profile == null ? TEST_AVATAR_URL : profile.avatarUrl();
        boolean isOnline = profile != null && profile.isOnline();
        return new FriendshipDto.UserInfo(userId, name, avatarUrl, isOnline);
    }

    /** Lấy cả hai danh sách PENDING trong cùng một response. */
    public FriendshipDto.RequestLists getRequests(UUID userId) {
        List<FriendshipDto> sent = friendshipRepository.findPendingSent(userId)
                .stream()
                .map(friendship -> FriendshipDto.fromSent(
                        friendship, getTestUserInfo(friendship.getReceiverId())))
                .toList();

        List<FriendshipDto> received = friendshipRepository.findPendingReceived(userId)
                .stream()
                .map(friendship -> FriendshipDto.fromReceived(
                        friendship, getTestUserInfo(friendship.getSenderId())))
                .toList();

        return new FriendshipDto.RequestLists(sent, received);
    }

    public List<FriendshipDto> getFriends(UUID userId) {
        return friendshipRepository.findFriends(userId)
                .stream()
                .map(friendship -> {
                    UUID friendId = userId.equals(friendship.getSenderId())
                            ? friendship.getReceiverId()
                            : friendship.getSenderId();
                    return FriendshipDto.fromFriend(getTestUserInfo(friendId));
                })
                .toList();
    }

    public FriendshipStatusDto getRelationshipStatus(UUID currentUserId, UUID otherUserId) {
        validateDifferentUsers(currentUserId, otherUserId);
        // ensureAccountExists(otherUserId); // Tạm bỏ do chưa tích hợp module User.

        FriendshipDto.UserInfo user = getTestUserInfo(otherUserId);
        return friendshipRepository.findBetween(currentUserId, otherUserId)
                .map(friendship -> {
                    if (FriendshipEntity.ACCEPTED.equals(friendship.getStatus())) {
                        return toRelationshipStatus(user, "ACCEPTED", friendship.getId(), "Bạn bè", null);
                    }
                    String direction = currentUserId.equals(friendship.getSenderId())
                            ? "SENT" : "RECEIVED";
                    String message = "SENT".equals(direction)
                            ? "Đã gửi lời mời" : "Bạn đã nhận lời mời kết bạn";
                    return toRelationshipStatus(user, "PENDING", friendship.getId(), message, direction);
                })
                .orElseGet(() -> toRelationshipStatus(user, "NONE", null, "Thêm bạn", null));
    }

    private FriendshipStatusDto toRelationshipStatus(
            FriendshipDto.UserInfo user,
            String status,
            UUID friendshipId,
            String message,
            String direction) {
        return new FriendshipStatusDto(
                user.id(), status, friendshipId, message,
                user.id(), user.name(), user.avatarUrl(), user.isOnline(), direction);
    }

    private FriendshipEntity getPendingRequestForUpdate(UUID requestId) {
        FriendshipEntity request = friendshipRepository.findByIdForUpdate(requestId)
                .orElseThrow(() -> new ApiException(409, "Lời mời kết bạn không còn hiệu lực"));

        if (!FriendshipEntity.PENDING.equals(request.getStatus())) {
            throw new ApiException(409, "Lời mời kết bạn không còn hiệu lực");
        }
        return request;
    }

    // private void ensureAccountExists(UUID userId) {
    // if (!userAccountLookupService.exists(userId)) {
    // throw new ApiException(404, "Tài khoản người dùng không tồn tại");
    // }
    // }

    private void validateDifferentUsers(UUID currentUserId, UUID otherUserId) {
        if (currentUserId == null || otherUserId == null) {
            throw new ApiException(400, "Thiếu mã người dùng");
        }
        if (currentUserId.equals(otherUserId)) {
            throw new ApiException(400, "Bạn không thể gửi lời mời hoặc kết bạn với chính mình");
        }
    }
}
