package com.meta.junior.dto;

import com.meta.junior.entity.GroupRole;
import java.util.UUID;

public record GroupMembershipStatusDto(UUID groupId, String status, GroupRole role) {}
