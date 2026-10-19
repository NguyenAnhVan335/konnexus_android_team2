package com.meta.junior.repository;

import com.meta.junior.common.FriendRequestStatus;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.entity.Friendship;
import com.meta.junior.entity.User;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class FriendshipRepo
        implements PanacheRepositoryBase<Friendship, UUID> {

    @Inject
    EntityManager em;

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

    public PageResponseDTO<User> getFriends(UUID currentUserId, int page, int size) {
        page = Math.max(0, page);
        size = Math.max(1, Math.min(size, 100));

        String sql = """
            SELECT friend.*
            FROM (
                SELECT u.id AS friend_id, u.*
                FROM friendships f
                JOIN users u ON u.id = f.receiver_id
                WHERE f.sender_id = :userId
                  AND f.status = 'ACCEPTED'

                UNION ALL

                SELECT u.id AS friend_id, u.*
                FROM friendships f
                JOIN users u ON u.id = f.sender_id
                WHERE f.receiver_id = :userId
                  AND f.status = 'ACCEPTED'
            ) friend
            ORDER BY friend.friend_id
            LIMIT :size OFFSET :offset
            """;

        @SuppressWarnings("unchecked")
        List<User> items = em
                .createNativeQuery(sql, User.class)
                .setParameter("userId", currentUserId)
                .setParameter("size", size)
                .setParameter("offset", (long) page * size)
                .getResultList();

        String countSql = """
            SELECT COUNT(*)
            FROM friendships f
            WHERE f.status = 'ACCEPTED'
              AND (
                  f.sender_id = :userId
                  OR f.receiver_id = :userId
              )
            """;

        Number count = (Number) em
                .createNativeQuery(countSql)
                .setParameter("userId", currentUserId)
                .getSingleResult();

        long totalElements = count.longValue();

        int totalPages = (int) Math.ceil(
                (double) totalElements / size
        );

        return PageResponseDTO.of(
                items,
                page,
                size,
                totalElements,
                totalPages
        );
    }

}