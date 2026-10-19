package com.meta.junior.dto;

import lombok.Data;

import java.util.UUID;

@Data
public class UpdateNotificationDTO {
    public UUID notificationId;
    public boolean isRead;
}
