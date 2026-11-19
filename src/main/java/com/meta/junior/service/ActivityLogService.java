package com.meta.junior.service;

import com.meta.junior.common.ActivityType;
import com.meta.junior.dto.social_media.activity.ActivityLogResponseDTO;
import com.meta.junior.entity.ActivityLog;
import com.meta.junior.exception.ApiException;
import com.meta.junior.repository.ActivityLogRepo;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.UUID;

/**
 * Ghi nhận và đọc "Lịch sử hoạt động" (7 ngày gần nhất theo mặc định).
 */
@ApplicationScoped
public class ActivityLogService {

    /** Giới hạn độ dài preview theo yêu cầu nghiệp vụ. */
    private static final int PREVIEW_MAX_LENGTH = 80;
    /** Khoảng thời gian mặc định khi client không truyền `from`. */
    private static final int DEFAULT_DAYS = 7;
    /** Chặn response quá lớn khi người dùng có nhiều hoạt động. */
    private static final int MAX_ITEMS = 200;

    @Inject
    ActivityLogRepo activityLogRepo;

    /**
     * Ghi một hoạt động của người dùng vào DB.
     *
     * <p>Được gọi bên trong transaction của service nghiệp vụ
     * (`PostServiceImpl`, `PostInteractionServiceImpl`, `FriendshipService`);
     * nếu ghi log thất bại thì cả thao tác nghiệp vụ cũng rollback để không có
     * hành động nào bị "mất lịch sử".</p>
     */
    @Transactional
    public void log(UUID userId, ActivityType actionType, UUID targetId, String targetPreview) {
        if (userId == null || actionType == null) {
            return;
        }
        ActivityLog entry = ActivityLog.builder()
                .user_id(userId)
                .action_type(actionType)
                .target_id(targetId)
                .target_preview(truncatePreview(targetPreview))
                .build();
        activityLogRepo.persist(entry);
    }

    /**
     * Lịch sử hoạt động của chính người dùng, mới nhất trước.
     *
     * @param from ISO-8601 (`2026-11-11T00:00:00`) hoặc ngày (`2026-11-11`);
     *             null/rỗng = `to - 7 ngày`.
     * @param to   ISO-8601 hoặc ngày; null/rỗng = thời điểm hiện tại.
     */
    public List<ActivityLogResponseDTO> getActivities(UUID userId, String from, String to) {
        LocalDateTime toTime = parseParam(to, LocalDateTime.now(), "to", true);
        LocalDateTime fromTime = parseParam(from, toTime.minusDays(DEFAULT_DAYS), "from", false);

        if (fromTime.isAfter(toTime)) {
            throw new ApiException(400, "Khoảng thời gian không hợp lệ: 'from' phải trước 'to'");
        }

        PanacheQuery<ActivityLog> query = activityLogRepo.findActivities(userId, fromTime, toTime);
        return query.page(0, MAX_ITEMS).list().stream()
                .map(ActivityLogResponseDTO::from)
                .toList();
    }

    private String truncatePreview(String preview) {
        if (preview == null) {
            return null;
        }
        String value = preview.trim().replaceAll("\\s+", " ");
        if (value.isEmpty()) {
            return null;
        }
        if (value.length() <= PREVIEW_MAX_LENGTH) {
            return value;
        }
        return value.substring(0, PREVIEW_MAX_LENGTH - 1).trim() + "…";
    }

    private LocalDateTime parseParam(String raw, LocalDateTime fallback, String name, boolean endOfDay) {
        if (raw == null || raw.isBlank()) {
            return fallback;
        }
        String value = raw.trim();
        try {
            // Cho phép truyền riêng ngày: "to" lấy hết ngày, "from" lấy đầu ngày.
            if (value.length() == 10) {
                LocalDate date = LocalDate.parse(value);
                return endOfDay ? date.atTime(23, 59, 59) : date.atStartOfDay();
            }
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException error) {
            throw new ApiException(400,
                    "Tham số '" + name + "' không hợp lệ. Dùng định dạng ISO-8601, ví dụ 2026-11-11T00:00:00");
        }
    }
}
