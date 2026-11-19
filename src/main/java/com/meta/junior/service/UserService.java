package com.meta.junior.service;
import com.meta.junior.common.ApiResponse;
import com.meta.junior.common.SystemRole;
import com.meta.junior.dto.ChangePasswordRequestDTO;
import com.meta.junior.dto.RegisterRequestDTO;
import com.meta.junior.dto.UpdateProfileDTO;
import com.meta.junior.dto.UserDTO;
import com.meta.junior.entity.User;
import com.meta.junior.repository.UserRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class UserService {

    @Inject
    UserRepo userRepo;

    @Inject
    JsonWebToken jwt;

    @Inject
    EmailService emailService;

    public List<User> getAll(){
        List<User> list = userRepo.findAll().list();
        return list;
    }
    @Transactional
    public Response addUser(UserDTO dto){
        User existing_user = userRepo.find("email = ?1 or username = ?2", dto.email, dto.username).firstResult();
        if(existing_user!=null)
            return Response.status(400)
                    .entity(
                            Map.of("message", "Email or username already exists")
                    )
                    .build();
        User newUser = new User();
        newUser.setUsername(dto.username);
        newUser.setEmail(dto.email);
        newUser.setPassword(dto.password);
        newUser.setRole(dto.role);

        userRepo.persist(newUser);
        return Response.ok(
                Map.of("message", "Adding successfully")
        ).build();
    }
    @Transactional
    public Response updateUser(UUID id, UpdateProfileDTO dto){
        UUID myUserId = UUID.fromString(jwt.getSubject());
        if(!id.equals(myUserId)){
            return Response.serverError()
                    .entity(
                            Map.of(
                                    "message",
                                    "unauthenticate"
                            )
                    ).build();
        }
        User existing_user = userRepo.findById(id);
        if(existing_user==null)
            return Response.status(404)
                    .entity(
                            Map.of("message", "User not found")
                    )
                    .build();
        User checkEmail_Username = userRepo.find("email = ?1 or username = ?2", dto.email, dto.username).firstResult();
        if(checkEmail_Username!=null && !checkEmail_Username.getId().equals(id))
            return Response.status(400)
                    .entity(
                            Map.of("message", "Email or username already exists")
                    )
                    .build();

        existing_user.setEmail(dto.email);
        existing_user.setUsername(dto.username);
        existing_user.setAvatar_url(dto.avatar_url);

        return Response.ok(
                Map.of("message", "Updating successfully")
        ).build();
    }

    /**
     * Đổi mật khẩu: bắt buộc xác thực mật khẩu hiện tại trước khi đặt mật khẩu mới.
     * Tách riêng khỏi luồng cập nhật hồ sơ để tránh vô tình ghi đè mật khẩu.
     */
    @Transactional
    public Response changePassword(UUID userId, ChangePasswordRequestDTO dto) {
        User user = userRepo.findById(userId);
        if (user == null) {
            return Response.status(404)
                    .entity(Map.of("message", "User not found"))
                    .build();
        }

        String currentPassword = dto.currentPassword == null ? "" : dto.currentPassword;
        String newPassword = dto.newPassword == null ? "" : dto.newPassword.trim();

        if (!currentPassword.equals(user.getPassword())) {
            return Response.status(400)
                    .entity(Map.of("message", "Mật khẩu hiện tại không đúng"))
                    .build();
        }
        if (newPassword.length() < 6) {
            return Response.status(400)
                    .entity(Map.of("message", "Mật khẩu mới phải có ít nhất 6 ký tự"))
                    .build();
        }
        if (newPassword.equals(currentPassword)) {
            return Response.status(400)
                    .entity(Map.of("message", "Mật khẩu mới phải khác mật khẩu hiện tại"))
                    .build();
        }

        user.setPassword(newPassword);
        return Response.ok(ApiResponse.success("Đổi mật khẩu thành công", null)).build();
    }
    @Transactional
    public Response deleteUser(UUID id){
        User existing_user = userRepo.findById(id);
        if(existing_user==null)
            return Response.status(404)
                    .entity(
                            Map.of("message", "User not found")
                    )
                    .build();
        userRepo.delete(existing_user);
        return Response.ok(
                Map.of("message", "Deleting successfully")
        ).build();
    }
    public boolean isValidRole(String role){
        for(SystemRole r : SystemRole.values()){
            if(r.name().equals(role))
                return true;
        }
        return false;
    }

    //Update user'status
    @Transactional
    public void updateUserStatus(UUID userId, boolean isOnline) {
        User user = userRepo.findById(userId);
        if (user == null) {
            return;
        }
        user.set_online(isOnline);
        user.setLast_seen(LocalDateTime.now());
    }

    @Transactional
    public Response registerUser(RegisterRequestDTO dto) {
        User existing_user = userRepo.find("email = ?1 or username = ?2", dto.email, dto.username).firstResult();
        if(existing_user!=null)
            return Response.status(400)
                    .entity(
                            Map.of("message", "Email or username already exists")
                    )
                    .build();
        User newUser = new User();
        newUser.setUsername(dto.username);
        newUser.setEmail(dto.email);
        newUser.setPassword(dto.password);
        newUser.set_online(false);
        newUser.setCreated_at(LocalDateTime.now());
        newUser.setRole(SystemRole.USER);
        // Tài khoản mới chưa xác thực email.
        newUser.set_active(false);
        String token = UUID.randomUUID().toString();
        newUser.setVerification_token(token);

        userRepo.persist(newUser);

        // Gửi email xác thực (hiện ghi log link vì chưa cấu hình SMTP).
        emailService.sendVerificationEmail(newUser.getEmail(), token);

        return Response.ok(
                Map.of("message", "Đăng ký thành công. Vui lòng kiểm tra email để xác thực tài khoản.")
        ).build();
    }

    /** Xác thực email theo token đã gửi. */
    @Transactional
    public Response verifyEmail(String token) {
        if (token == null || token.isBlank()) {
            return Response.status(400)
                    .entity(Map.of("message", "Thiếu mã xác thực"))
                    .build();
        }
        User user = userRepo.find("verification_token = ?1", token).firstResult();
        if (user == null) {
            return Response.status(400)
                    .entity(Map.of("message", "Mã xác thực không hợp lệ hoặc đã hết hạn"))
                    .build();
        }
        user.set_active(true);
        user.setVerification_token(null);
        return Response.ok(ApiResponse.success("Xác thực email thành công. Bạn có thể đăng nhập.", null)).build();
    }


    public User login(String username, String password) {
        User existing_user = userRepo.find("username = ?1 AND password = ?2", username, password).firstResult();
        return existing_user;
    }

    public long countAllUsers() {
        return userRepo.count();
    }

    /** Số người dùng đang online (`is_online = true`). */
    public long countOnlineUsers() {
        return userRepo.count("is_online = true");
    }

    @Transactional
    public void anonymizeUser(UUID userId) {
        User user = userRepo.findById(userId);
        if (user != null) {
            user.setUsername("Người dùng đã xóa");
            user.setEmail("deleted_" + UUID.randomUUID().toString() + "@chatify.com");
            user.setPassword(UUID.randomUUID().toString());
            user.setAvatar_url("https://cdn-icons-png.flaticon.com/512/149/149071.png");

            userRepo.persist(user);
        }
    }

}
