package com.meta.junior.dto.post;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.util.Map;

/**
 * Reaction (emoji) summary of a post, returned inside {@link PostDetailResponse#reactions()}:
 * <pre>
 * { "total": 3, "by_type": { "LIKE": 2, "LOVE": 1 }, "my_reaction": "LIKE" }
 * </pre>
 *
 * <p>Reactions are stored in the {@code emojis} table (rows whose {@code post_id} is set) and are
 * maintained by the emoji module; this DTO is a read-only aggregation for the Post API.</p>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record ReactionSummaryResponse(
        int total,
        Map<String, Integer> byType,
        String myReaction
) {
    public static ReactionSummaryResponse empty() {
        return new ReactionSummaryResponse(0, Map.of(), null);
    }
}
