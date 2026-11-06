package com.meta.junior.dto;

import com.meta.junior.entity.GroupPrivacy;
import com.meta.junior.entity.GroupRole;
import java.time.LocalDateTime;
import java.util.UUID;

public record GroupDto(
        UUID id, String name, String description, GroupPrivacy privacy,
        UUID ownerId, String coverUrl, boolean requirePostApproval,
        long memberCount, GroupRole myRole, LocalDateTime createdAt) {}
