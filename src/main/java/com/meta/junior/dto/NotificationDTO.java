package alan.nguyen.dto.connexa.nortification;

import alan.nguyen.common.NortificationType;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationDTO {

    public UUID receiver_id;

    public UUID actor_id;

    public NortificationType type;

    public UUID post_id;

    public UUID comment_id;

}
