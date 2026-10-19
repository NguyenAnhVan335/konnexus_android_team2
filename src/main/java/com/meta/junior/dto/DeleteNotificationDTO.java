package com.meta.junior.dto;

import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class DeleteNotificationDTO {
    public List<UUID> target;
}
