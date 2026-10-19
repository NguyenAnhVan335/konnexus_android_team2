package com.meta.junior.dto.social_media.hashtag;
import com.meta.junior.entity.Hashtag;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HashtagResponseDTO {

    private UUID id;
    private String name;
    private int usage_count;
    private LocalDateTime created_at;

    public static HashtagResponseDTO fromEntity(Hashtag entity) {
        if (entity == null) {
            return null;
        }
        return HashtagResponseDTO.builder()
                .id(entity.getId())
                .name(entity.getName())
                .usage_count(entity.getUsage_count())
                .created_at(entity.getCreated_at())
                .build();
    }
}
