package com.meta.junior.service;

import com.meta.junior.dto.post.ReactionSummaryResponse;
import com.meta.junior.entity.Emoji;
import com.meta.junior.entity.PostComment;
import com.meta.junior.repository.EmojiRepository;
import com.meta.junior.repository.PostCommentRepository;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;

/**
 * Read-only aggregation of the interaction data (reactions + comments) needed by the Post API.
 *
 * <p>The data itself belongs to the emoji / comment modules — this service never writes to those
 * tables, it only reads them (through their repositories and, for the batch counters, through
 * aggregate JPQL queries) so the Post API can report {@code like_count}, {@code comment_count},
 * {@code _liked}, the reaction summary and the comment list.</p>
 *
 * <p>Reactions are rows of {@code emojis} whose {@code post_id} is not null; comments are rows of
 * {@code post_comments} with {@code status = true}.</p>
 */
@ApplicationScoped
public class PostInteractionService {

    @Inject
    EmojiRepository emojiRepository;

    @Inject
    PostCommentRepository postCommentRepository;

    @Inject
    EntityManager entityManager;

    /**
     * Counts the reactions of each post.
     *
     * @param postIds posts to count for
     * @param from    when not {@code null}, only reactions created at or after this instant are
     *                counted (used by the trending window). When {@code null} the whole history is
     *                counted.
     * @return a map {@code postId -> reaction count}; posts without reactions are absent
     */
    public Map<UUID, Integer> countReactionsByPost(Collection<UUID> postIds, LocalDateTime from) {
        if (postIds == null || postIds.isEmpty()) {
            return Map.of();
        }
        String jpql = "select e.postId, count(e) from Emoji e"
                + " where e.postId in :postIds"
                + (from != null ? " and e.createdAt >= :from" : "")
                + " group by e.postId";
        TypedQuery<Object[]> query = entityManager.createQuery(jpql, Object[].class)
                .setParameter("postIds", List.copyOf(postIds));
        if (from != null) {
            query.setParameter("from", from);
        }
        return toCountMap(query.getResultList());
    }

    /**
     * Counts the active comments of each post. See {@link #countReactionsByPost(Collection, LocalDateTime)}
     * for the meaning of {@code from}.
     */
    public Map<UUID, Integer> countCommentsByPost(Collection<UUID> postIds, LocalDateTime from) {
        if (postIds == null || postIds.isEmpty()) {
            return Map.of();
        }
        String jpql = "select c.postId, count(c) from PostComment c"
                + " where c.status = true and c.postId in :postIds"
                + (from != null ? " and c.createdAt >= :from" : "")
                + " group by c.postId";
        TypedQuery<Object[]> query = entityManager.createQuery(jpql, Object[].class)
                .setParameter("postIds", List.copyOf(postIds));
        if (from != null) {
            query.setParameter("from", from);
        }
        return toCountMap(query.getResultList());
    }

    /**
     * Returns the ids of the posts the given user has reacted to.
     *
     * @return empty set when the caller is anonymous (no {@code X-User-Id}) or nothing matched
     */
    public Set<UUID> findReactedPostIds(UUID viewerId, Collection<UUID> postIds) {
        if (viewerId == null || postIds == null || postIds.isEmpty()) {
            return Set.of();
        }
        return Set.copyOf(entityManager.createQuery(
                        "select distinct e.postId from Emoji e"
                                + " where e.authorId = :viewerId and e.postId in :postIds",
                        UUID.class)
                .setParameter("viewerId", viewerId)
                .setParameter("postIds", List.copyOf(postIds))
                .getResultList());
    }

    /**
     * Aggregates the reactions of a single post: total, breakdown per emoji type and the reaction of
     * the given viewer ({@code null} when the viewer has not reacted or is anonymous).
     */
    public ReactionSummaryResponse summarize(UUID postId, UUID viewerId) {
        List<Emoji> reactions = emojiRepository.findByPostId(postId);
        Map<String, Integer> byType = new TreeMap<>();
        String myReaction = null;
        for (Emoji reaction : reactions) {
            byType.merge(reaction.emojiType, 1, Integer::sum);
            if (viewerId != null && viewerId.equals(reaction.authorId)) {
                myReaction = reaction.emojiType;
            }
        }
        return new ReactionSummaryResponse(reactions.size(), byType, myReaction);
    }

    /**
     * Returns the active comments of a post, oldest first.
     */
    public List<PostComment> findComments(UUID postId) {
        return postCommentRepository.findByPostId(postId).stream()
                .filter(comment -> comment.status)
                .sorted(Comparator.comparing(
                        (PostComment comment) -> comment.createdAt,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
    }

    private static Map<UUID, Integer> toCountMap(List<Object[]> rows) {
        Map<UUID, Integer> counts = new LinkedHashMap<>();
        for (Object[] row : rows) {
            if (row[0] == null) {
                continue;
            }
            counts.put((UUID) row[0], ((Number) row[1]).intValue());
        }
        return counts;
    }
}
