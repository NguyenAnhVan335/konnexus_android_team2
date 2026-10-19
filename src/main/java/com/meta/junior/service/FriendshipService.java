package com.meta.junior.service;

import com.meta.junior.common.FriendRequestStatus;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.friendship.FriendshipRequestDTO;
import com.meta.junior.dto.social_media.friendship.FriendshipResponseDTO;
import com.meta.junior.entity.Friendship;
import com.meta.junior.entity.User;
import com.meta.junior.repository.FriendshipRepo;
import com.meta.junior.repository.UserRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotAuthorizedException;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class FriendshipService {

    @Inject
    FriendshipRepo friendshipRepo;

    @Inject
    UserRepo userRepo;

    @Inject
    JsonWebToken jwt;

    /**
     * UC: Gửi lời mời kết bạn
     */
    @Transactional
    public FriendshipResponseDTO sendRequest(
            UUID senderId,
            FriendshipRequestDTO dto
    ) {
        if (dto == null || dto.getReceiverId() == null) {
            throw new WebApplicationException(
                    Response.status(Response.Status.BAD_REQUEST)
                            .entity(Map.of("message", "Thiếu thông tin người nhận"))
                            .build()
            );
        }

        UUID receiverId = dto.getReceiverId();

        // 1. Không cho phép gửi cho chính mình (HTTP 400 Bad Request)
        if (senderId.equals(receiverId)) {
            throw new WebApplicationException(
                    Response.status(Response.Status.BAD_REQUEST)
                            .entity(Map.of("message", "Không thể gửi lời mời kết bạn cho chính mình"))
                            .build()
            );
        }

        // 2. Kiểm tra người gửi tồn tại (HTTP 404 Not Found)
        User sender = userRepo.findByIdOptional(senderId)
                .orElseThrow(() -> new WebApplicationException(
                        Response.status(Response.Status.NOT_FOUND)
                                .entity(Map.of("message", "Không tìm thấy người gửi"))
                                .build()
                ));

        // 3. Kiểm tra người nhận tồn tại (HTTP 404 Not Found)
        User receiver = userRepo.findByIdOptional(receiverId)
                .orElseThrow(() -> new WebApplicationException(
                        Response.status(Response.Status.NOT_FOUND)
                                .entity(Map.of("message", "Không tìm thấy người nhận"))
                                .build()
                ));

        // 4. Kiểm tra đã là bạn chưa (HTTP 400 Bad Request)
        if (friendshipRepo.areFriends(senderId, receiverId)) {
            throw new WebApplicationException(
                    Response.status(Response.Status.BAD_REQUEST)
                            .entity(Map.of("message", "Hai người đã là bạn bè"))
                            .build()
            );
        }

        // 5. Kiểm tra đã có lời mời PENDING (HTTP 409 Conflict)
        if (friendshipRepo.existsBetweenUsers(
                senderId,
                receiverId,
                FriendRequestStatus.PENDING
        )) {
            throw new WebApplicationException(
                    Response.status(Response.Status.CONFLICT)
                            .entity(Map.of("message", "Bạn đã gửi lời mời kết bạn cho người này rồi"))
                            .build()
            );
        }

        // 6. Tạo FriendRequest
        Friendship friendship = Friendship.builder()
                .sender(sender)
                .receiver(receiver)
                .status(FriendRequestStatus.PENDING)
                .build();

        // 7. Lưu database
        friendshipRepo.persistAndFlush(friendship);
        return FriendshipResponseDTO.from(friendship);
    }

    /**
     * UC: Chấp nhận lời mời kết bạn
     */
    @Transactional
    public FriendshipResponseDTO acceptRequest(
            UUID currentUserId,
            UUID requestId
    ) {
        Friendship request = friendshipRepo.findByIdAndReceiver(requestId, currentUserId);

        if (request == null) {
            throw new WebApplicationException(
                    Response.status(Response.Status.NOT_FOUND)
                            .entity(Map.of("message", "Không tìm thấy lời mời kết bạn"))
                            .build()
            );
        }

        if (request.getStatus() != FriendRequestStatus.PENDING) {
            throw new WebApplicationException(
                    Response.status(Response.Status.BAD_REQUEST)
                            .entity(Map.of("message", "Lời mời đã được xử lý"))
                            .build()
            );
        }

        request.setStatus(FriendRequestStatus.ACCEPTED);
        friendshipRepo.flush();
        return FriendshipResponseDTO.from(request);
    }

    /**
     * UC: Từ chối lời mời kết bạn
     */
    @Transactional
    public FriendshipResponseDTO rejectRequest(
            UUID currentUserId,
            UUID requestId
    ) {
        Friendship request = friendshipRepo.findByIdAndReceiver(requestId, currentUserId);

        if (request == null) {
            throw new WebApplicationException(
                    Response.status(Response.Status.NOT_FOUND)
                            .entity(Map.of("message", "Không tìm thấy lời mời kết bạn"))
                            .build()
            );
        }

        if (request.getStatus() != FriendRequestStatus.PENDING) {
            throw new WebApplicationException(
                    Response.status(Response.Status.BAD_REQUEST)
                            .entity(Map.of("message", "Lời mời đã được xử lý"))
                            .build()
            );
        }

        request.setStatus(FriendRequestStatus.REJECTED);
        friendshipRepo.flush();
        return FriendshipResponseDTO.from(request);
    }

    public PageResponseDTO<User> getAllFriends(UUID id, int page, int size) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        return friendshipRepo.getFriends(id, page, size);
    }

    @Transactional
    public void deleteRelationship(UUID id) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        if(currentUserId.equals(id))
            throw new NotAuthorizedException("You are not allowed to perform this action");
        if(!friendshipRepo.areFriends(id, currentUserId))
            throw new RuntimeException("You can not perform this action.");
        friendshipRepo.delete("(sender.id = ?1 AND receiver.id = ?2) OR" +
                " (sender.id = ?3 AND receiver.id = ?4)", id, currentUserId, currentUserId, id);
    }
}