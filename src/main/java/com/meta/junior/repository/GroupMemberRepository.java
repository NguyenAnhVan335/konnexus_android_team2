package com.meta.junior.repository;

import com.meta.junior.entity.GroupMemberEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class GroupMemberRepository implements PanacheRepositoryBase<GroupMemberEntity, UUID> {
    public Optional<GroupMemberEntity> findMembership(UUID groupId, UUID userId) {
        return find("groupId = ?1 and userId = ?2", groupId, userId).firstResultOptional();
    }

    public List<GroupMemberEntity> findMembers(UUID groupId) {
        return list("groupId = ?1 order by joinedAt asc", groupId);
    }

    public List<GroupMemberEntity> findByUser(UUID userId) {
        return list("userId = ?1 order by joinedAt desc", userId);
    }

    public long countMembers(UUID groupId) { return count("groupId", groupId); }
}
