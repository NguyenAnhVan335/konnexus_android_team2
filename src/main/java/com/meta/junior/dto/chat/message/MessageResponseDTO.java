package com.meta.junior.dto.chat.message;


public class MessageResponseDTO {
    public String content;
    public String username;

    public MessageResponseDTO(String username, String content) {
        this.username = username;
        this.content = content;
    }
}
