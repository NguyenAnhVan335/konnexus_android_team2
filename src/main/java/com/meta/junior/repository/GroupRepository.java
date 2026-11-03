package com.meta.junior.repository;

import com.meta.junior.entity.GroupEntity;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class GroupRepository implements PanacheRepositoryBase<GroupEntity, UUID> {
    public Optional<GroupEntity> findActive(UUID id) {
        return find("id = ?1 and deletedAt is null", id).firstResultOptional();
    }

    public Optional<GroupEntity> findActiveForUpdate(UUID id) {
        return find("id = ?1 and deletedAt is null", id)
                .withLock(LockModeType.PESSIMISTIC_WRITE).firstResultOptional();
    }

    public List<GroupEntity> search(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return list("deletedAt is null order by createdAt desc");
        }
        return list("deletedAt is null and lower(name) like ?1 order by createdAt desc",
                "%" + keyword.trim().toLowerCase(java.util.Locale.ROOT) + "%");
    }
}
