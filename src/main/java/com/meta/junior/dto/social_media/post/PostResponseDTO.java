package com.meta.junior.dto.social_media.post;

import com.meta.junior.common.PostPrivacy;
import com.meta.junior.entity.Post;
import lombok.*;


import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

/**
 * DTO dữ liệu đầy đủ của bài viết gửi về cho Client
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PostResponseDTO {

    private UUID id;
    private AuthorResponseDTO author;
    private String content;
    private PostPrivacy privacy;
    private int like_count;
    private int comment_count;
    private boolean is_liked;
    private boolean is_edited;
    private List<PostMediaDTO> media_list;
    @Builder.Default
    private List<String> hashtags = Collections.emptyList();
    private LocalDateTime created_at;
    private LocalDateTime updated_at;

    public static PostResponseDTO fromEntity(Post post) {
        return fromEntity(post, Collections.emptyList());
    }

    public static PostResponseDTO fromEntity(Post post, List<String> hashtags) {
        if (post == null) {
            return null;
        }

        List<PostMediaDTO> media = post.getMediaList() == null
                ? Collections.emptyList()
                : post.getMediaList().stream()
                .map(PostMediaDTO::fromEntity)
                .toList();

        return fromEntity(post, hashtags, media);
    }

    /**
     * Mapper an toàn cho luồng Batch Loading:
     * Nhận trực tiếp hashtags và mediaList đã được nạp sẵn từ ngoài,
     * tuyệt đối KHÔNG gọi post.getMediaList() để tránh Lazy Loading N+1.
     */
    public static PostResponseDTO fromEntity(Post post, List<String> hashtags, List<PostMediaDTO> mediaList) {
        if (post == null) {
            return null;
        }

        return PostResponseDTO.builder()
                .id(post.getId())
                .author(AuthorResponseDTO.fromEntity(post.getAuthor()))
                .content(post.getContent())
                .privacy(post.getPrivacy())
                .like_count(post.getLike_count())
                .comment_count(post.getComment_count())
                .is_liked(false) // Mặc định false, giai đoạn 2 sẽ kiểm tra user hiện tại đã like chưa
                .is_edited(post.is_edited())
                .media_list(mediaList != null ? mediaList : Collections.emptyList())
                .hashtags(hashtags != null ? hashtags : Collections.emptyList())
                .created_at(post.getCreated_at())
                .updated_at(post.getUpdated_at())
                .build();
    }
}
