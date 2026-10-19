package com.meta.junior.repository;


import com.meta.junior.common.FriendRequestStatus;
import com.meta.junior.entity.Friendship;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class FriendshipSearchRepo
        implements PanacheRepositoryBase<Friendship, Long> {

    public boolean areFriends(UUID user1, UUID user2) {

        return count(
                """
                (
                    (sender.id = ?1 AND receiver.id = ?2)
                    OR
                    (sender.id = ?2 AND receiver.id = ?1)
                )
                AND status = ?3
                """,
                user1,
                user2,
                FriendRequestStatus.ACCEPTED
        ) > 0;
    }

    public boolean hasPendingRequest(UUID user1, UUID user2) {

        return count(
                """
                (
                    (sender.id = ?1 AND receiver.id = ?2)
                    OR
                    (sender.id = ?2 AND receiver.id = ?1)
                )
                AND status = ?3
                """,
                user1,
                user2,
                FriendRequestStatus.PENDING
        ) > 0;
    }

    public long countMutualFriends(UUID user1, UUID user2) {

        var friendsOfUser1 = find(
                """
                (
                    sender.id = ?1
                    OR
                    receiver.id = ?1
                )
                AND status = ?2
                """,
                user1,
                FriendRequestStatus.ACCEPTED
        ).list();

        var friendsOfUser2 = find(
                """
                (
                    sender.id = ?1
                    OR
                    receiver.id = ?1
                )
                AND status = ?2
                """,
                user2,
                FriendRequestStatus.ACCEPTED
        ).list();

        java.util.Set<UUID> set1 = new java.util.HashSet<>();

        for (Friendship request : friendsOfUser1) {

            UUID friendId;

            if (request.getSender().getId().equals(user1)) {
                friendId = request.getReceiver().getId();
            } else {
                friendId = request.getSender().getId();
            }

            set1.add(friendId);
        }

        java.util.Set<UUID> set2 = new java.util.HashSet<>();

        for (Friendship request : friendsOfUser2) {

            UUID friendId;

            if (request.getSender().getId().equals(user2)) {
                friendId = request.getReceiver().getId();
            } else {
                friendId = request.getSender().getId();
            }

            set2.add(friendId);
        }

        set1.retainAll(set2);

        return set1.size();
    }
}