package com.meta.junior.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public class EmojiResponse {
    public UUID id;
    public String emojiType;
    public UUID postId;
    public UUID cmtId;
    public UUID authorId;
    public LocalDateTime createdAt;
    public boolean active;
}