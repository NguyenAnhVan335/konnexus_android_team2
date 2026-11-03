package com.meta.junior.repository;

import com.meta.junior.entity.GroupPostEntity;
import com.meta.junior.entity.GroupPostStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class GroupPostRepository implements PanacheRepositoryBase<GroupPostEntity, UUID> {
    public List<GroupPostEntity> published(UUID groupId) {
        return list("groupId = ?1 and deletedAt is null and status = ?2 order by createdAt desc",
                groupId, GroupPostStatus.PUBLISHED);
    }

    public List<GroupPostEntity> pending(UUID groupId) {
        return list("groupId = ?1 and deletedAt is null and status = ?2 order by createdAt asc",
                groupId, GroupPostStatus.PENDING);
    }

    public List<GroupPostEntity> mine(UUID groupId, UUID userId) {
        return list("groupId = ?1 and authorId = ?2 and deletedAt is null order by createdAt desc",
                groupId, userId);
    }

    public Optional<GroupPostEntity> findActive(UUID groupId, UUID postId) {
        return find("id = ?1 and groupId = ?2 and deletedAt is null", postId, groupId).firstResultOptional();
    }
}
