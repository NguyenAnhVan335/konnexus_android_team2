package com.meta.junior.service;

import jakarta.enterprise.context.ApplicationScoped;
import org.jboss.logging.Logger;

/**
 * Gửi email xác thực tài khoản.
 *
 * Dự án hiện chưa cấu hình SMTP (chưa thêm quarkus-mailer), nên luồng này ghi
 * link xác thực ra log để môi trường phát triển có thể xác minh thủ công.
 * Khi có SMTP, chỉ cần thay nội dung phương thức này bằng việc gọi Mailer mà
 * không ảnh hưởng tới phần còn lại của luồng xác thực.
 */
@ApplicationScoped
public class EmailService {

    private static final Logger LOG = Logger.getLogger(EmailService.class);

    public void sendVerificationEmail(String email, String token) {
        String verificationLink = "http://localhost:8080/api/auth/verify?token=" + token;
        LOG.infof("[EmailVerification] Gửi email xác thực tới %s. Mở link: %s", email, verificationLink);
    }
}
