package alan.nguyen.entity;


import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
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
@Table(name = "conversations")
public class Conversation{
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "type")
    private String conversation_type;
    @Column(name = "title")
    private String title;
    @Column(name = "avatar_url")
    private String avatar_url;
    @Column(name = "created_by")
    private UUID created_by;
    @Column(name = "created_at")
    private LocalDateTime created_at;
}
