package com.meta.junior.dto;

import com.meta.junior.entity.GroupJoinStatus;
import java.time.LocalDateTime;
import java.util.UUID;

public record GroupJoinRequestDto(UUID id, UUID groupId, UUID userId,
        GroupJoinStatus status, LocalDateTime createdAt) {}
