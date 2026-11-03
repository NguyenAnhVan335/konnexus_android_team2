package com.meta.junior.dto;

import com.meta.junior.entity.GroupPostStatus;
import java.time.LocalDateTime;
import java.util.UUID;

public record GroupPostDto(UUID id, UUID groupId, UUID authorId, String content,
        GroupPostStatus status, LocalDateTime createdAt, LocalDateTime updatedAt) {}
