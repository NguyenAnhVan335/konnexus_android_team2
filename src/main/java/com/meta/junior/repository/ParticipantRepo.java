package com.meta.junior.repository;


import com.meta.junior.common.GroupRole;
import com.meta.junior.dto.chat.conversation.MemberResponseDTO;
import com.meta.junior.entity.Participant;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.Response;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class ParticipantRepo implements PanacheRepositoryBase<Participant, UUID> {

    @Inject
    UserRepo userRepo;

    public List<MemberResponseDTO> getMembers(UUID conversationId) {
        String query = "SELECT p.user_id, u.username, p.group_role, u.avatar_url " +
                "FROM Participant p " +
                "JOIN User u ON p.user_id = u.id " +
                "WHERE p.conversation_id = ?1 " +
                "ORDER BY p.group_role ASC";
        return getEntityManager()
                .createQuery(query, MemberResponseDTO.class)
                .setParameter(1, conversationId)
                .getResultList();
    }

    public long promotingRole(UUID conversationId, UUID userId, GroupRole role) {
        long updated_row = update("group_role = ?1 WHERE conversation_id = ?2 AND user_id = ?3",role, conversationId, userId);
        return updated_row;
    }

    public long kickUser(UUID conversationId, UUID userId) {
        long deleted_row = delete("conversation_id = ?1 AND user_id = ?2", conversationId, userId);

        return deleted_row;
    }

    public Response addMember(UUID conversationId, List<UUID> memberIds) {
        List<Participant> participants = new ArrayList<>();
        for(UUID user_id : memberIds){
            participants.add(new Participant(GroupRole.MEMBER, user_id, conversationId));
        }
        persist(participants);
        return Response.ok(participants).build();
    }
}
