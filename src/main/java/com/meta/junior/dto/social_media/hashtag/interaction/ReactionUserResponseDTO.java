package com.meta.junior.dto.social_media.hashtag.interaction;

import com.meta.junior.common.ReactionType;
import com.meta.junior.entity.PostReaction;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReactionUserResponseDTO {
    private UUID authorId;
    private String authorName;
    private String authorAvatarUrl;
    private ReactionType type;
    private LocalDateTime createdAt;

    public static ReactionUserResponseDTO fromEntity(PostReaction reaction) {
        if (reaction == null || reaction.getAuthor() == null) {
            return null;
        }

        return ReactionUserResponseDTO.builder()
                .authorId(reaction.getAuthor().getId())
                .authorName(reaction.getAuthor().getUsername())
                .authorAvatarUrl(reaction.getAuthor().getAvatar_url())
                .type(reaction.getType())
                .createdAt(reaction.getCreatedAt())
                .build();
    }
}