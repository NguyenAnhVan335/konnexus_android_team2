package com.meta.junior.group;

import io.quarkus.runtime.LaunchMode;
import io.quarkus.security.identity.SecurityIdentity;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.HttpHeaders;

import java.util.Optional;
import java.util.UUID;

/**
 * Isolation adapter for Groups. In dev/test, use X-Test-User-Id.
 * Production requires a verified authenticated SecurityIdentity with a UUID principal.
 * Never trust a caller-chosen UUID header in production.
 *
 * This class is deliberately separate from the common CurrentUserProvider,
 * which reads X-User-Id and may be used by other team modules.
 */
@RequestScoped
public class GroupActorProvider {
    @Inject HttpHeaders headers;
    @Inject SecurityIdentity identity;

    public UUID requireUserId() {
        return optionalUserId().orElseThrow(() ->
                new GroupApiException(401, "Thiếu X-Test-User-Id (UUID) khi kiểm thử"));
    }

    public Optional<UUID> optionalUserId() {
        if (identity != null && !identity.isAnonymous()) {
            String principal = identity.getPrincipal().getName();
            try {
                return Optional.of(UUID.fromString(principal));
            } catch (IllegalArgumentException ex) {
                throw new GroupApiException(401, "Danh tính xác thực không chứa UUID hợp lệ");
            }
        }
        if (LaunchMode.current() == LaunchMode.NORMAL) {
            return Optional.empty();
        }
        String value = headers.getHeaderString("X-Test-User-Id");
        if (value == null || value.isBlank()) return Optional.empty();
        try {
            return Optional.of(UUID.fromString(value.trim()));
        } catch (IllegalArgumentException ex) {
            throw new GroupApiException(400, "X-Test-User-Id phải là UUID hợp lệ");
        }
    }
}
