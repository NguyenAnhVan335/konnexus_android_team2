package com.meta.junior.dto.social_media.hashtag.interaction;

import com.meta.junior.entity.PostComment;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class CommentResponseDTO {
    private UUID id;
    private UUID postId;
    private UUID authorId;
    private String authorUsername;
    private String authorAvatarUrl;
    private String content;
    private UUID parentId;
    private LocalDateTime createdAt;

    public static CommentResponseDTO fromEntity(PostComment comment) {
        return CommentResponseDTO.builder()
                .id(comment.getId())
                .postId(comment.getPost().getId())
                .authorId(comment.getAuthor().getId())
                .authorUsername(comment.getAuthor().getUsername())
                .authorAvatarUrl(comment.getAuthor().getAvatar_url())
                .content(comment.getContent())
                .parentId(comment.getParentComment() != null ? comment.getParentComment().getId() : null)
                .createdAt(comment.getCreatedAt())
                .build();
    }
}