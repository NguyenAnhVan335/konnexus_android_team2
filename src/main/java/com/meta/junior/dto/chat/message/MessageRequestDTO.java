package com.meta.junior.dto.chat.message;

import java.util.UUID;

public class MessageRequestDTO {

    //type: CHAT, TYPING, READ
    public String type = "CHAT";
    public UUID conversation_id;
    public String content;
    public String attachment_url;
    //used for read message feature
    public UUID message_id;
}
