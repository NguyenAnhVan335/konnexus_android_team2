package com.meta.junior.dto.social_media.hashtag.interaction;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateCommentRequestDTO {
    @NotBlank(message = "Nội dung bình luận không được để trống")
    private String content;
}
