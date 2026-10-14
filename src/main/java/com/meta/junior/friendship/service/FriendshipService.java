package com.meta.junior.friendship.service;

import com.meta.junior.friendship.dto.FriendshipDto;
import com.meta.junior.friendship.dto.FriendshipStatusDto;
import com.meta.junior.friendship.entity.FriendshipEntity;
import com.meta.junior.friendship.exception.ApiException;
import com.meta.junior.friendship.repository.FriendshipRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class FriendshipService {

    @Inject
    FriendshipRepository friendshipRepository;

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

    public List<FriendshipDto> getReceivedRequests(UUID userId) {
        return friendshipRepository.findPendingReceived(userId)
                .stream()
                .map(FriendshipDto::from)
                .toList();
    }

    public List<FriendshipDto> getSentRequests(UUID userId) {
        return friendshipRepository.findPendingSent(userId)
                .stream()
                .map(FriendshipDto::from)
                .toList();
    }

    public List<FriendshipDto> getFriends(UUID userId) {
        return friendshipRepository.findFriends(userId)
                .stream()
                .map(FriendshipDto::from)
                .toList();
    }

    public FriendshipStatusDto getRelationshipStatus(UUID currentUserId, UUID otherUserId) {
        validateDifferentUsers(currentUserId, otherUserId);
        // ensureAccountExists(otherUserId);

        return friendshipRepository.findBetween(currentUserId, otherUserId)
                .map(friendship -> {
                    if (FriendshipEntity.ACCEPTED.equals(friendship.getStatus())) {
                        return new FriendshipStatusDto(
                                otherUserId, "FRIENDS", friendship.getId(), "Bạn bè");
                    }
                    if (currentUserId.equals(friendship.getSenderId())) {
                        return new FriendshipStatusDto(
                                otherUserId, "REQUEST_SENT", friendship.getId(), "Đã gửi lời mời");
                    }
                    return new FriendshipStatusDto(
                            otherUserId, "REQUEST_RECEIVED", friendship.getId(), "Bạn đã nhận lời mời kết bạn");
                })
                .orElseGet(() -> new FriendshipStatusDto(
                        otherUserId, "NONE", null, "Thêm bạn"));
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
