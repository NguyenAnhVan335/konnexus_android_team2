package com.meta.junior.service;
import com.meta.junior.entity.MessageRead;
import com.meta.junior.entity.User;
import com.meta.junior.repository.MessageReadRepo;
import com.meta.junior.repository.UserRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@ApplicationScoped
public class MessageReadService {

    @Inject
    MessageReadRepo messageReadRepo;

    @Inject
    UserRepo userRepo;

    @Transactional
    public void markAsRead(UUID messageId, UUID senderId) {
        MessageRead messageRead = new MessageRead();
        User existing_user = userRepo.findById(senderId);
        if(existing_user==null)
            throw new RuntimeException("User not found");
        messageRead.setUser_id(senderId);
        messageRead.setMessage_id(messageId);
        messageRead.setRead_at(LocalDateTime.now());
        messageReadRepo.persist(messageRead);
    }
}
