package com.meta.junior.service.auth;

import com.meta.junior.dto.LoginRequestDTO;
import com.meta.junior.entity.User;
import com.meta.junior.service.UserService;
import io.smallrye.jwt.build.Jwt;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.ws.rs.core.Response;

import java.util.Map;
import java.util.UUID;

@Singleton
public class JwtService {

    @Inject
    UserService userService;

    public String generateJwt(UUID id,String role){

        long duration = System.currentTimeMillis() + 3600;
        return Jwt.issuer("chatify-jwt")
                .subject(id.toString())
                .groups(role)
                .expiresAt(duration)
                .sign();
    }

    public Response getToken(LoginRequestDTO dto) {
        User existing_user = userService.login(dto.username, dto.password);
        if(existing_user==null)
            return Response.status(404)
                    .entity(
                            Map.of("message", "Username or password is incorrect.")
                    )
                    .build();
        UUID myId = existing_user.getId();
        String role = existing_user.getRole().toString();

        userService.updateUserStatus(myId, true);

        String token = generateJwt(myId, role);
        return Response.ok(
                Map.of("token", token)
                )
                .build();
    }

}
