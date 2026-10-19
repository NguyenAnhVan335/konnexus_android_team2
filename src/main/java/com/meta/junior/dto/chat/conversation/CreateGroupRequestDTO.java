package alan.nguyen.dto.chatify.conversation;

import java.util.List;
import java.util.UUID;

public class CreateGroupRequestDTO {
    public UUID creatorId;
    public String title;
    public List<UUID> memberIds;
    public String avatar_url;
}
