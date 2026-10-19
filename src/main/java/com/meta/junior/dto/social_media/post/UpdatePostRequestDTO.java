package com.meta.junior.dto.social_media.post;
import com.meta.junior.common.PostPrivacy;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

/**
 * Payload yêu cầu cập nhật bài viết từ Client
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdatePostRequestDTO {

    @NotBlank(message = "Nội dung bài viết không được để trống")
    @Size(max = 2000, message = "Nội dung bài viết không được vượt quá 2000 ký tự")
    private String content;

    @NotNull(message = "Quyền riêng tư không được để trống")
    private PostPrivacy privacy;
}
