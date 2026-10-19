package com.meta.junior.service;


import com.meta.junior.dto.chat.message.MessageResponseDTO;
import com.meta.junior.entity.Message;
import com.meta.junior.repository.MessageRepo;
import com.meta.junior.repository.ParticipantRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.Response;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;


@ApplicationScoped
public class MessageService {

    @Inject
    ParticipantRepo paticipantRepo;

    @Inject
    MessageRepo messageRepo;

    //Get all messages in group
    public List<Message> getMessages(UUID conversation_id, UUID user_id, int page, int size){

        //Check: user is a member in this conversation?
        long count = paticipantRepo.count("conversation_id = ?1 and user_id = ?2", conversation_id, user_id);

        if(count==0)
            throw new WebApplicationException("Bạn không có quyền xem tin nhắn của phòng này", Response.Status.FORBIDDEN);

        return messageRepo.find(
                        "conversation_id = ?1 order by created_at desc",
                        conversation_id
                )
                .page(page, size)
                .list();
    }

    @Transactional
    public Message sendMessage(UUID user_id, UUID conversation_id, String content, String attachment_url){
        if(!user_id.equals(UUID.fromString("2d61b0d1-1512-494b-ba1d-bf1c55de1173"))){
            long count = paticipantRepo.count("conversation_id = ?1 and user_id = ?2", conversation_id, user_id);
            if (count == 0) {
                throw new WebApplicationException("Bạn không thể gửi tin nhắn vào phòng này", Response.Status.FORBIDDEN);
            }
        }
        Message msg = new Message();
        msg.setConversation_id(conversation_id);
        msg.setUser_id(user_id);
        msg.setContent(content);
        msg.setAttachment_url(attachment_url);
        msg.setCreated_at(LocalDateTime.now());

        messageRepo.persist(msg);

        return msg;
    }

    //get 20 latest messages in group
    public List<MessageResponseDTO> getRecentMessages(UUID conversationId) {
        String query = "SELECT m.content, u.username FROM Message m " +
                "JOIN User u ON m.user_id = u.id " +
                "WHERE m.conversation_id = ?1 AND m.attachment_url IS NULL " +
                "ORDER BY m.created_at ASC " +
                "LIMIT 20";
        return messageRepo.getEntityManager()
                .createQuery(query, MessageResponseDTO.class)
                .setParameter(1, conversationId)
                .getResultList();
    }

    public long countMessagesToday() {
        LocalDate today = LocalDate.now();

        LocalDateTime start = today.atStartOfDay();
        LocalDateTime end = today.atTime(LocalTime.MAX);
        return messageRepo.count("created_at BETWEEN ?1 AND ?2", start, end);
    }
}
