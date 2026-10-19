package com.meta.junior.entity;

import com.meta.junior.common.GroupRole;
import com.meta.junior.dto.chat.user.ParticipantDTO;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "participants")
public class Participant{
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "conversation_id")
    private UUID conversation_id;
    @Column(name = "user_id")
    private UUID user_id;
    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private GroupRole group_role = GroupRole.MEMBER;


    public Participant(GroupRole group_role, UUID user_id, UUID conversation_id) {
        this.group_role = group_role;
        this.user_id = user_id;
        this.conversation_id = conversation_id;
    }

    public void map(ParticipantDTO dto){
        this.id = null;
        this.conversation_id = dto.getConversation_id();
        this.user_id = dto.getUser_id();
        this.group_role = GroupRole.MEMBER;
    }
}
