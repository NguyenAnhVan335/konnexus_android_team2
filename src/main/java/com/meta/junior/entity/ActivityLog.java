package com.meta.junior.entity;

import com.meta.junior.common.ActivityType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Một dòng lịch sử hoạt động của người dùng.
 *
 * <p>Chỉ lưu id người thực hiện (không map quan hệ tới {@link User}) để tránh
 * lazy-load và giữ bảng log độc lập với vòng đời tài khoản.</p>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "activity_logs")
public class ActivityLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Người thực hiện hành động (id lấy từ JWT subject). */
    @Column(name = "user_id", nullable = false)
    private UUID user_id;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", nullable = false)
    private ActivityType action_type;

    /** Id bài viết / bình luận / người nhận lời mời kết bạn. */
    @Column(name = "target_id")
    private UUID target_id;

    /** Đoạn mô tả ngắn (tối đa 80 ký tự) để hiển thị trong timeline. */
    @Column(name = "target_preview", length = 80)
    private String target_preview;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime created_at;

    @PrePersist
    protected void onCreate() {
        if (this.created_at == null) {
            this.created_at = LocalDateTime.now();
        }
    }
}
