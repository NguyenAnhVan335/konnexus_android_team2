package com.meta.junior.dto;

import com.meta.junior.entity.GroupRole;
import java.time.LocalDateTime;
import java.util.UUID;

public record GroupMemberDto(UUID userId, GroupRole role, LocalDateTime joinedAt) {}
