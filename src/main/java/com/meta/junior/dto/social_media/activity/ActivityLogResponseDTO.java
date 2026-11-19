package com.meta.junior.dto.social_media.activity;

import com.meta.junior.common.ActivityType;
import com.meta.junior.entity.ActivityLog;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ActivityLogResponseDTO {

    private UUID id;
    private UUID user_id;
    private ActivityType action_type;
    private UUID target_id;
    private String target_preview;
    private LocalDateTime created_at;

    public static ActivityLogResponseDTO from(ActivityLog log) {
        return new ActivityLogResponseDTO(
                log.getId(),
                log.getUser_id(),
                log.getAction_type(),
                log.getTarget_id(),
                log.getTarget_preview(),
                log.getCreated_at()
        );
    }
}
