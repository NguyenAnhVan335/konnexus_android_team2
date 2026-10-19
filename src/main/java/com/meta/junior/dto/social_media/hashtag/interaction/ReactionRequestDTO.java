package com.meta.junior.dto.social_media.hashtag.interaction;

import com.meta.junior.common.ReactionType;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReactionRequestDTO {
    @NotNull(message = "Loại biểu cảm không được để trống")
    private ReactionType type;
}