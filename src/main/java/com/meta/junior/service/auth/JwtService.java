package com.meta.junior.service.auth;

import com.meta.junior.common.SystemRole;
import com.meta.junior.dto.LoginRequestDTO;
import com.meta.junior.entity.User;
import com.meta.junior.service.UserService;
import io.smallrye.jwt.build.Jwt;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import jakarta.ws.rs.core.Response;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Singleton
public class JwtService {

    @Inject
    UserService userService;

    public String generateJwt(UUID id,String role){

        // Trước đây truyền `System.currentTimeMillis() + 3600` (millis) vào
        // `expiresAt(long)` vốn nhận epoch seconds khiến token gần như không hết hạn.
        // Đổi sang Instant để token hết hạn đúng 1 giờ.
        Instant expiresAt = Instant.now().plusSeconds(3600);
        return Jwt.issuer("konnexus-jwt")
                .subject(id.toString())
                .groups(role)
                .claim("admin", SystemRole.ADMIN.name().equals(role))
                .expiresAt(expiresAt)
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
        if (!existing_user.is_active()) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity(
                            Map.of("message", "Tài khoản chưa xác thực email. Vui lòng kiểm tra email và mở link xác thực.")
                    )
                    .build();
        }
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
