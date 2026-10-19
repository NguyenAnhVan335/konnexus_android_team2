package com.meta.junior.dto.social_media.hashtag.interaction;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.UUID;

@Data
public class CreateCommentRequestDTO {
    @NotBlank(message = "Nội dung bình luận không được để trống")
    private String content;

    private UUID parentId;
}