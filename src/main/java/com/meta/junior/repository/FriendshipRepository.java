package com.meta.junior.repository;

import com.meta.junior.entity.FriendshipEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class FriendshipRepository implements PanacheRepositoryBase<FriendshipEntity, UUID> {

    public Optional<FriendshipEntity> findBetween(UUID firstUserId, UUID secondUserId) {
        return find(
                "(senderId = ?1 and receiverId = ?2) or (senderId = ?2 and receiverId = ?1)",
                firstUserId,
                secondUserId).firstResultOptional();
    }

    public Optional<FriendshipEntity> findByIdForUpdate(UUID id) {
        return find("id", id)
                .withLock(LockModeType.PESSIMISTIC_WRITE)
                .firstResultOptional();
    }

    public List<FriendshipEntity> findPendingReceived(UUID userId) {
        return list(
                "receiverId = ?1 and status = ?2 order by id",
                userId,
                FriendshipEntity.PENDING);
    }

    public List<FriendshipEntity> findPendingSent(UUID userId) {
        return list(
                "senderId = ?1 and status = ?2 order by id",
                userId,
                FriendshipEntity.PENDING);
    }

    public List<FriendshipEntity> findFriends(UUID userId) {
        return list(
                "(senderId = ?1 or receiverId = ?1) and status = ?2 order by id",
                userId,
                FriendshipEntity.ACCEPTED);
    }
}
