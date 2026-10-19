package alan.nguyen.entity;

import alan.nguyen.common.NortificationType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "receiver_id")
    private  UUID receiver_id;

    @Column(name = "actor_id")
    private UUID actor_id;

    @Column(name = "type", nullable = false)
    @Enumerated(EnumType.STRING)
    private NortificationType type;

    @Column(name = "post_id")
    private UUID post_id;

    @Column(name = "comment_id")
    private UUID comment_id;

    @Column(name = "is_read")
    private boolean is_read;

    @Column(name = "created_at")
    private LocalDateTime created_at;
}
