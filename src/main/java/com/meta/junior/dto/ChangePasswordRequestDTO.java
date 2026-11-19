package com.meta.junior.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Yêu cầu đổi mật khẩu: bắt buộc nhập mật khẩu hiện tại để xác thực.
 */
public class ChangePasswordRequestDTO {

    @NotBlank(message = "Vui lòng nhập mật khẩu hiện tại")
    public String currentPassword;

    @NotBlank(message = "Vui lòng nhập mật khẩu mới")
    @Size(min = 6, max = 100, message = "Mật khẩu mới phải có ít nhất 6 ký tự")
    public String newPassword;
}
