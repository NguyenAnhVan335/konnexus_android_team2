package com.meta.junior.repository;

import com.meta.junior.entity.ActivityLog;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.time.LocalDateTime;
import java.util.UUID;

@ApplicationScoped
public class ActivityLogRepo implements PanacheRepositoryBase<ActivityLog, UUID> {

    /**
     * Hoạt động của một người dùng trong khoảng thời gian, mới nhất trước.
     */
    public PanacheQuery<ActivityLog> findActivities(UUID userId, LocalDateTime from, LocalDateTime to) {
        return find(
                "user_id = ?1 AND created_at >= ?2 AND created_at <= ?3 ORDER BY created_at DESC",
                userId, from, to);
    }
}
