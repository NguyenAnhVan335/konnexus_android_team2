package com.meta.junior.repository;

import com.meta.junior.entity.Post;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import io.quarkus.panache.common.Sort;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class PostRepository implements PanacheRepository<Post> {

    /**
     * Finds an active (non soft-deleted) post by id.
     */
    public Optional<Post> findActiveById(UUID id) {
        return find("id = ?1 and status = true", id).firstResultOptional();
    }

    /**
     * Returns a query over all active posts ordered by creation date descending.
     */
    public PanacheQuery<Post> findActive() {
        return find("status = true", Sort.descending("createdAt"));
    }

    /**
     * Returns a query over all active posts of a given author, ordered by creation date descending.
     */
    public PanacheQuery<Post> findActiveByAuthor(UUID authorId) {
        return find("authorId = ?1 and status = true", Sort.descending("createdAt"), authorId);
    }
}
