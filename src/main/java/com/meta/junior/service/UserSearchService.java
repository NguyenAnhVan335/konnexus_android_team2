package com.meta.junior.service;

import com.meta.junior.dto.social_media.UserSearchResponseDTO;
import com.meta.junior.entity.User;
import com.meta.junior.repository.FriendshipSearchRepo;
import com.meta.junior.repository.UserSearchRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class UserSearchService {

    @Inject
    UserSearchRepo userSearchRepo;

    @Inject
    FriendshipSearchRepo friendshipSearchRepo;

    public List<UserSearchResponseDTO> search(
            String keyword,
            UUID currentUserId
    ) {

        if (keyword == null || keyword.trim().isEmpty()) {
            return List.of();
        }

        keyword = keyword.trim();

        List<User> users =
                userSearchRepo.searchUsers(
                        keyword,
                        currentUserId
                );

        List<UserSearchResponseDTO> result =
                new ArrayList<>();

        for (User user : users) {

            String relationship;

            if (friendshipSearchRepo
                    .areFriends(currentUserId, user.getId())) {

                relationship = "FRIEND";

            } else if (friendshipSearchRepo
                    .hasPendingRequest(currentUserId, user.getId())) {

                relationship = "PENDING";

            } else {

                relationship = "NONE";
            }

            long mutualFriends =
                    friendshipSearchRepo.countMutualFriends(
                            currentUserId,
                            user.getId()
                    );

            result.add(
                    new UserSearchResponseDTO(
                            user.getId(),
                            user.getUsername(),
                            user.getEmail(),
                            user.getAvatar_url(),
                            relationship,
                            mutualFriends
                    )
            );
        }

        /*
         * Người có nhiều bạn chung được đưa lên trước.
         */
        result.sort(
                Comparator
                        .comparingLong(
                                UserSearchResponseDTO
                                        ::getMutualFriends
                        )
                        .reversed()
                        .thenComparing(
                                UserSearchResponseDTO
                                        ::getUsername,
                                String.CASE_INSENSITIVE_ORDER
                        )
        );

        return result;
    }
}