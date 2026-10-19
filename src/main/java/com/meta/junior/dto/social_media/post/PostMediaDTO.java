package com.meta.junior.dto.social_media.post;

import com.meta.junior.common.PostMediaType;
import com.meta.junior.entity.PostMedia;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.util.UUID;

/**
 * DTO đại diện cho một tệp media (ảnh/video) đính kèm bài viết
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PostMediaDTO {

    private UUID id;

    @NotBlank(message = "Đường dẫn media không được để trống")
    private String media_url;

    @Builder.Default
    private PostMediaType media_type = PostMediaType.IMAGE;

    @Builder.Default
    private int display_order = 0;

    public static PostMediaDTO fromEntity(PostMedia entity) {
        if (entity == null) {
            return null;
        }
        return PostMediaDTO.builder()
                .id(entity.getId())
                .media_url(entity.getMedia_url())
                .media_type(entity.getMedia_type())
                .display_order(entity.getDisplay_order())
                .build();
    }
}


