package com.meta.junior.entity;

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
@Table(name = "message_reads")
public class MessageRead {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "message_id")
    private UUID message_id;
    @Column(name = "user_id")
    private UUID user_id;
    @Column(name = "read_at")
    private LocalDateTime read_at;
}
