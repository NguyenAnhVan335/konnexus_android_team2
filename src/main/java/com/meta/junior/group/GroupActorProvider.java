package com.meta.junior.group;

import com.meta.junior.exception.ApiException;
import io.quarkus.runtime.LaunchMode;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.HttpHeaders;
import java.util.Optional;
import java.util.UUID;

/**
 * Development/test-only identity bridge scoped to the Groups module.
 * Never trust a client-supplied user-id header for production authorization.
 * Replace with the actual authenticated user's JWT/session identity before deploying.
 */
@RequestScoped
public class GroupActorProvider {
    @Inject HttpHeaders headers;
    @Inject SecurityIdentity identity;

    public UUID requireUserId() {
        return optionalUserId().orElseThrow(
                () -> new ApiException(401, "Thiếu X-Test-User-Id (UUID) khi kiểm thử"));
    }

    public Optional<UUID> optionalUserId() {
        if (!identity.isAnonymous()) {
            try {
                return Optional.of(UUID.fromString(identity.getPrincipal().getName()));
            } catch (IllegalArgumentException ex) {
                throw new ApiException(401, "JWT subject không chứa UUID hợp lệ");
            }
        }
        if (LaunchMode.current() == LaunchMode.NORMAL) {
            return Optional.empty(); // Test headers are disabled in production.
        }
        String header = headers.getHeaderString("X-Test-User-Id");
        if (header == null || header.isBlank()) return Optional.empty();
        try {
            return Optional.of(UUID.fromString(header.trim()));
        } catch (IllegalArgumentException ex) {
            throw new ApiException(400, "X-Test-User-Id phải là UUID hợp lệ");
        }
    }
}
