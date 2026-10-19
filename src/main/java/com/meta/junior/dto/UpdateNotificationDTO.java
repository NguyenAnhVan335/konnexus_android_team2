package alan.nguyen.dto.connexa.nortification;

import alan.nguyen.common.NortificationType;
import lombok.Data;

import java.util.UUID;

@Data
public class UpdateNotificationDTO {
    public UUID nortificationId;
    public boolean isRead;
}
