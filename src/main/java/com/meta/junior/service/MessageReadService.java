package alan.nguyen.service;

import alan.nguyen.entity.MessageRead;
import alan.nguyen.entity.User;
import alan.nguyen.repository.MessageReadRepo;
import alan.nguyen.repository.UserRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.core.Response;

import java.time.LocalDateTime;
import java.util.Map;
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
