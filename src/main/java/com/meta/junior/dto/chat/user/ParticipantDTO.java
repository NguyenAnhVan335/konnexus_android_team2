package alan.nguyen.dto.chatify.user;

import lombok.Data;

import java.util.UUID;

@Data
public class ParticipantDTO {
    private UUID conversation_id;
    private UUID user_id;
    private String group_role;
}
