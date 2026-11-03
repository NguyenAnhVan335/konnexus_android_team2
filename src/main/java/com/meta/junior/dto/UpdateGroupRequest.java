package com.meta.junior.dto;

import com.meta.junior.entity.GroupPrivacy;
import jakarta.validation.constraints.Size;

public record UpdateGroupRequest(
        @Size(max = 120) String name,
        @Size(max = 2000) String description,
        GroupPrivacy privacy,
        @Size(max = 1024) String coverUrl,
        Boolean requirePostApproval) {}
