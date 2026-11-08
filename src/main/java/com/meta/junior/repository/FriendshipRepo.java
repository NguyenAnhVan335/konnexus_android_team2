package com.meta.junior.repository;

import com.meta.junior.common.FriendRequestStatus;
import com.meta.junior.entity.Friendship;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class FriendshipRepo
        implements PanacheRepositoryBase<Friendship, UUID> {

    /**
     * Kiểm tra giữa 2 user đã tồn tại FriendRequest
     * với trạng thái truyền vào hay chưa.
     */
    public boolean existsBetweenUsers(
            UUID user1,
            UUID user2,
            FriendRequestStatus status
    ) {

        long count = count(
                "(sender.id = ?1 and receiver.id = ?2 " +
                        "or sender.id = ?2 and receiver.id = ?1) " +
                        "and status = ?3",
                user1,
                user2,
                status
        );

        return count > 0;
    }

    /**
     * Kiểm tra 2 user đã là bạn hay chưa.
     *
     * Hai người được xem là bạn nếu FriendRequest
     * giữa họ có status ACCEPTED.
     */
    public boolean areFriends(
            UUID user1,
            UUID user2
    ) {

        return existsBetweenUsers(
                user1,
                user2,
                FriendRequestStatus.ACCEPTED
        );
    }

    /**
     * Tìm lời mời theo ID và người nhận.
     *
     * Điều này đảm bảo chỉ người nhận lời mời
     * mới có quyền accept/reject.
     */
    public Friendship findByIdAndReceiver(
            UUID requestId,
            UUID receiverId
    ) {

        return find(
                "id = ?1 and receiver.id = ?2",
                requestId,
                receiverId
        ).withLock(LockModeType.PESSIMISTIC_WRITE)
                .firstResult();
    }

    /**Danh sách bạn bè đã ACCEPTED.*/
    public List<Friendship> findFriends(UUID userId) {
        return list("(sender.id = ?1 or receiver.id = ?1) and status = ?2", userId, FriendRequestStatus.ACCEPTED);
    }

    /**Danh sách lời mời kết bạn đã nhận (PENDING).*/
    public List<Friendship> findPendingReceived(UUID userId) {
        return list("receiver.id = ?1 and status = ?2", userId, FriendRequestStatus.PENDING);
    }

    /**Danh sách lời mời kết bạn đã gửi (PENDING).*/
    public List<Friendship> findPendingSent(UUID userId) {
        return list("sender.id = ?1 and status = ?2", userId, FriendRequestStatus.PENDING);
    }

    /**Tìm quan hệ giữa 2 user (bất kể trạng thái).*/
    public Optional<Friendship> findBetween(UUID user1, UUID user2) {
        return find("(sender.id = ?1 and receiver.id = ?2) or (sender.id = ?2 and receiver.id = ?1)", user1, user2)
                .firstResultOptional();
    }
}