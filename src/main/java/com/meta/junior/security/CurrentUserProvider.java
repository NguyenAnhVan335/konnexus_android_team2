package com.meta.junior.security;

import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotAuthorizedException;
import jakarta.ws.rs.core.HttpHeaders;

import java.util.UUID;

/**
 * Resolves the id of the currently authenticated user.
 *
 * <p><strong>TODO (authentication):</strong> the project already declares {@code quarkus-smallrye-jwt}
 * on the classpath but authentication is not wired up yet (no protected endpoints, no user lookup).
 * Once JWT authentication is enabled, inject {@code io.quarkus.security.identity.SecurityIdentity} or
 * {@code org.eclipse.microprofile.jwt.JsonWebToken} here and resolve the user id from the token
 * (for example the {@code sub} or {@code userId} claim) instead of reading a plain header.</p>
 *
 * <p>Until then this placeholder reads the {@code X-User-Id} header so the Post API remains testable.
 * This must not be used in production.</p>
 */
@RequestScoped
public class CurrentUserProvider {

    @Inject
    HttpHeaders httpHeaders;

    public UUID getCurrentUserId() {
        UUID userId = getCurrentUserIdOrNull();
        if (userId == null) {
            throw new NotAuthorizedException("Authentication required: X-User-Id header is missing");
        }
        return userId;
    }

    /**
     * Resolves the current user id, or {@code null} when the request is anonymous (no
     * {@code X-User-Id} header).
     *
     * <p>Used by the read endpoints of the Post API: an anonymous visitor is allowed to browse, but
     * only sees {@code PUBLIC} posts. A malformed header is still rejected with 400 so a client bug
     * never silently downgrades a logged-in user to a guest.</p>
     */
    public UUID getCurrentUserIdOrNull() {
        String header = httpHeaders.getHeaderString("X-User-Id");
        if (header == null || header.isBlank()) {
            return null;
        }
        try {
            return UUID.fromString(header.trim());
        } catch (IllegalArgumentException ex) {
            throw new BadRequestException("X-User-Id header must be a valid UUID");
        }
    }
}
