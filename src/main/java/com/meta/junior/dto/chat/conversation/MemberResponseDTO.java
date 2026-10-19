package alan.nguyen.dto.chatify.conversation;

import alan.nguyen.common.GroupRole;

import java.util.UUID;

public class MemberResponseDTO {
    public UUID user_id;
    public String username;
    public GroupRole group_role;
    public String avatar_url;

    public MemberResponseDTO(UUID user_id, String username, GroupRole group_role, String avatar_url) {
        this.user_id = user_id;
        this.username = username;
        this.group_role = group_role;
        this.avatar_url = avatar_url;
    }
}
