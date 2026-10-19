package com.meta.junior.service;


import com.meta.junior.common.GroupRole;
import com.meta.junior.dto.chat.conversation.UpdateConvDTO;
import com.meta.junior.entity.Conversation;
import com.meta.junior.entity.Participant;
import com.meta.junior.entity.User;
import com.meta.junior.repository.ConversationRepo;
import com.meta.junior.repository.MessageRepo;
import com.meta.junior.repository.ParticipantRepo;
import com.meta.junior.repository.UserRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.core.Response;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class ConversationService {

    @Inject
    ConversationRepo conversationRepo;
    @Inject
    ParticipantRepo paticipantRepository;
    @Inject
    MessageRepo messageRepo;

    @Inject
    UserRepo userRepo;

    @Transactional
    public Response createGroupChat(UUID creator_id, String title, List<UUID> member_id, String avatar_url){
        //Init and save group
        Conversation conversation = new Conversation();
        conversation.setConversation_type("GROUP");
        conversation.setTitle(title);
        conversation.setCreated_by(creator_id);
        conversation.setCreated_at(LocalDateTime.now());
        conversation.setAvatar_url(avatar_url);
        conversationRepo.persist(conversation);

        //Create participant list
        List<Participant> participants = new ArrayList<>();
        participants.add(new Participant(GroupRole.ADMIN, creator_id, conversation.getId()));
        for (UUID memberId : member_id){
            User existing_user = userRepo.findById(memberId);
            if(existing_user==null)
                return Response.status(404)
                                .entity(
                                        Map.of("message", "User not found")
                                ).build();
            participants.add(new Participant(GroupRole.MEMBER, memberId, conversation.getId()));
        }
        paticipantRepository.persist(participants);

        return Response.ok(conversation).build();
    }

    public List<Conversation> getUserConversations(UUID userId){
        return conversationRepo.getConversations(userId);
    }

    public List<UUID> getOnlineUsersId(UUID conversationId) {
        return conversationRepo.getOnlineUsersId(conversationId);
    }

    @Transactional
    public Response updateConv(UUID conversationId, UpdateConvDTO dto) {
        return conversationRepo.updateConv(conversationId, dto);
    }

    @Transactional
    public Response deleteGroup(UUID conversationId) {

        conversationRepo.deleteById(conversationId);
        messageRepo.delete("conversation_id = ?1", conversationId);
        paticipantRepository.delete("conversation_id = ?1", conversationId);

        return Response.ok().build();

    }

    public long countAllConversations() {
        return conversationRepo.count();
    }

    public List<Conversation> getAllRooms() {
        return conversationRepo.listAll();
    }
}
