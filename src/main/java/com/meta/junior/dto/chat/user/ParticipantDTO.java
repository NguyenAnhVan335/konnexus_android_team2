package com.meta.junior.dto.chat.user;

import lombok.Data;

import java.util.UUID;

@Data
public class ParticipantDTO {
    private UUID conversation_id;
    private UUID user_id;
    private String group_role;
}
