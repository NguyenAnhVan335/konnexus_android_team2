package alan.nguyen.dto.chatify.user;

import alan.nguyen.common.SystemRole;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UserDTO {
    public String username;
    public String email;
    public String password;
    public SystemRole role;
}
