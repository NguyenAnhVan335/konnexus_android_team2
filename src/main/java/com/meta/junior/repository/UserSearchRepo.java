package com.meta.junior.repository;

import com.meta.junior.entity.User;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class UserSearchRepo
        implements PanacheRepositoryBase<User, UUID> {

    public List<User> searchUsers(String keyword, UUID currentUserId) {

        String search = "%" + keyword.toLowerCase() + "%";

        return find(
                """
                (
                    LOWER(username) LIKE ?1
                    OR LOWER(email) LIKE ?1
                )
                AND id <> ?2
                ORDER BY username
                """,
                search,
                currentUserId
        ).list();
    }
}