package com.meta.junior.repository;

import com.meta.junior.dto.chat.conversation.UpdateConvDTO;
import com.meta.junior.entity.Conversation;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class ConversationRepo implements PanacheRepositoryBase<Conversation, UUID> {
    public List<Conversation> getConversations(UUID userId){
        String query = "SELECT c FROM Conversation c " +
                "JOIN Participant p ON c.id = p.conversation_id " +
                "WHERE p.user_id = ?1 ORDER BY c.created_at DESC";
        return find(query, userId).list();
    }

    public Optional<Conversation> findDirectBetween(UUID user1, UUID user2) {
        String query = "SELECT c FROM Conversation c " +
                "JOIN Participant p1 ON c.id = p1.conversation_id " +
                "JOIN Participant p2 ON c.id = p2.conversation_id " +
                "WHERE c.conversation_type = 'DIRECT' AND p1.user_id = ?1 AND p2.user_id = ?2";
        return find(query, user1, user2).firstResultOptional();
    }

    public List<UUID> getOnlineUsersId(UUID conversationId) {
        String query = "SELECT u.id FROM User u " +
                "JOIN Participant p ON u.id = p.user_id " +
                "WHERE p.conversation_id = ?1 AND u.is_online = true";

        return getEntityManager()
                .createQuery(query, UUID.class)
                .setParameter(1, conversationId)
                .getResultList();
    }

    public Response updateConv(UUID conversationId, UpdateConvDTO dto) {
        long updated_row = update("title = ?1, avatar_url = ?2 WHERE id = ?3", dto.title, dto.avatar_url, conversationId);
        if(updated_row==0)
            return Response.serverError().build();
        return Response.ok().build();
    }
}
