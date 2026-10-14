package com.meta.junior.repository;


import com.meta.junior.entity.User;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.core.Response;

import java.util.UUID;

@ApplicationScoped
public class UserRepo implements PanacheRepositoryBase<User, UUID> {
}
