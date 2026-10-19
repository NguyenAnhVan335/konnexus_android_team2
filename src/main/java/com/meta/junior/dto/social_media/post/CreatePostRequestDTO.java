package com.meta.junior.dto.social_media.post;

import com.meta.junior.common.PostPrivacy;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.util.List;

/**
 * Payload yêu cầu tạo bài viết mới từ Client
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreatePostRequestDTO {

    @NotBlank(message = "Nội dung bài viết không được để trống")
    @Size(max = 2000, message = "Nội dung bài viết không được vượt quá 2000 ký tự")
    private String content;

    @Builder.Default
    private PostPrivacy privacy = PostPrivacy.PUBLIC;

    @Valid
    @Size(max = 10, message = "Mỗi bài viết tối đa 10 tệp đa phương tiện")
    private List<PostMediaDTO> media_list;
}
