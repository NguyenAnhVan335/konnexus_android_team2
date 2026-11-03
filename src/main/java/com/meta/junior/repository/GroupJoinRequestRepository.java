package com.meta.junior.repository;

import com.meta.junior.entity.GroupJoinRequestEntity;
import com.meta.junior.entity.GroupJoinStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class GroupJoinRequestRepository implements PanacheRepositoryBase<GroupJoinRequestEntity, UUID> {
    public Optional<GroupJoinRequestEntity> findByGroupAndUser(UUID groupId, UUID userId) {
        return find("groupId = ?1 and userId = ?2", groupId, userId).firstResultOptional();
    }

    public List<GroupJoinRequestEntity> pendingInGroup(UUID groupId) {
        return list("groupId = ?1 and status = ?2 order by createdAt asc", groupId, GroupJoinStatus.PENDING);
    }
}
