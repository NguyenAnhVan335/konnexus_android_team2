package com.meta.junior.entity;

import com.meta.junior.common.SystemRole;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "username", unique = true)
    private String username;
    @Column(name = "email", unique = true)
    private String email;
    @Column(name = "password")
    private String password;
    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private SystemRole role = SystemRole.USER;
    @Column(name = "avatar_url")
    private String avatar_url;
    @Column(name = "is_online")
    private boolean is_online;
    @Column(name = "last_seen")
    private LocalDateTime last_seen;
    @Column(name = "created_at")
    private LocalDateTime created_at;
    //Tieu su cho nguoi dung
    @Column(name = "note")
    private String note;
    @Column(name = "birthday")
    private LocalDate birthday;

}
