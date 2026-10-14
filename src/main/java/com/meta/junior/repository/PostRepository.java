package com.meta.junior.repository;

import com.meta.junior.common.PostPrivacy;
import com.meta.junior.entity.Post;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import io.quarkus.panache.common.Sort;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Data access for {@link Post}.
 *
 * <p>Every read used by the API goes through a <em>visibility aware</em> query. A post is visible to a
 * viewer when:</p>
 * <ul>
 *   <li>it is not soft deleted ({@code status = true}), and</li>
 *   <li>its privacy is {@code PUBLIC}, or</li>
 *   <li>the viewer is the author (own posts, whatever the privacy), or</li>
 *   <li>its privacy is {@code FRIENDS} and the viewer is an accepted friend of the author.</li>
 * </ul>
 *
 * <p>An anonymous viewer (no {@code X-User-Id} header) only ever sees {@code PUBLIC} posts. The
 * filtering always happens in SQL — a post is never loaded into memory and then discarded, so a
 * {@code PRIVATE} post can never leak through the API.</p>
 */
@ApplicationScoped
public class PostRepository implements PanacheRepository<Post> {

    @Inject
    EntityManager entityManager;

    /**
     * Finds an active (non soft-deleted) post by id, ignoring privacy. Used by the
     * update/delete operations so a non-author gets 403 (instead of 404) on an existing post.
     */
    public Optional<Post> findActiveById(UUID id) {
        return find("id = ?1 and status = true", id).firstResultOptional();
    }

    /**
     * Returns a query over all posts visible to the viewer, ordered by creation date descending.
     *
     * @param viewerId  the current user, or {@code null} for an anonymous visitor
     * @param friendIds ids of the accepted friends of {@code viewerId} (may be empty)
     */
    public PanacheQuery<Post> findVisibleTo(UUID viewerId, List<UUID> friendIds, Sort sort) {
        return find(visibilityPredicate(viewerId, friendIds), sort, visibilityParams(viewerId, friendIds));
    }

    /**
     * Returns a query over the posts of {@code authorId} that are visible to the viewer, ordered by
     * creation date descending.
     */
    public PanacheQuery<Post> findVisibleByAuthor(UUID authorId, UUID viewerId, List<UUID> friendIds) {
        Map<String, Object> params = visibilityParams(viewerId, friendIds);
        params.put("authorId", authorId);
        return find(visibilityPredicate(viewerId, friendIds) + " and authorId = :authorId",
                Sort.descending("createdAt"),
                params);
    }

    /**
     * Finds a single post by id only if it is visible to the viewer.
     */
    public Optional<Post> findVisibleById(UUID id, UUID viewerId, List<UUID> friendIds) {
        Map<String, Object> params = visibilityParams(viewerId, friendIds);
        params.put("postId", id);
        return find(visibilityPredicate(viewerId, friendIds) + " and id = :postId", params)
                .firstResultOptional();
    }

    /**
     * Returns {@code [postId, createdAt]} of every post visible to the viewer, newest first.
     *
     * <p>Only the two columns needed to rank the trending feed are read (no entity, no media), and
     * the privacy filter is still applied in SQL.</p>
     */
    public List<Object[]> findVisibleIdAndCreatedAt(UUID viewerId, List<UUID> friendIds) {
        TypedQuery<Object[]> query = entityManager.createQuery(
                        "select p.id, p.createdAt from Post p where "
                                + visibilityPredicate(viewerId, friendIds)
                                + " order by p.createdAt desc, p.id asc",
                        Object[].class);
        visibilityParams(viewerId, friendIds).forEach(query::setParameter);
        return query.getResultList();
    }

    private static String visibilityPredicate(UUID viewerId, List<UUID> friendIds) {
        StringBuilder predicate = new StringBuilder("status = true and (privacy = :publicPrivacy");
        if (viewerId != null) {
            predicate.append(" or authorId = :viewerId");
        }
        if (viewerId != null && friendIds != null && !friendIds.isEmpty()) {
            predicate.append(" or (privacy = :friendsPrivacy and authorId in :friendIds)");
        }
        return predicate.append(')').toString();
    }

    private static Map<String, Object> visibilityParams(UUID viewerId, List<UUID> friendIds) {
        Map<String, Object> params = new HashMap<>();
        params.put("publicPrivacy", PostPrivacy.PUBLIC);
        if (viewerId != null) {
            params.put("viewerId", viewerId);
        }
        if (viewerId != null && friendIds != null && !friendIds.isEmpty()) {
            params.put("friendsPrivacy", PostPrivacy.FRIENDS);
            params.put("friendIds", List.copyOf(friendIds));
        }
        return params;
    }
}
