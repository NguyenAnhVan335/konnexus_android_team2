package alan.nguyen.service;

import alan.nguyen.dto.PageResponseDTO;
import alan.nguyen.dto.connexa.nortification.DeleteNotificationDTO;
import alan.nguyen.dto.connexa.nortification.NotificationDTO;
import alan.nguyen.dto.connexa.nortification.UpdateNotificationDTO;
import alan.nguyen.entity.Notification;
import alan.nguyen.entity.User;
import alan.nguyen.repository.NotificationRepo;
import alan.nguyen.repository.UserRepo;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotFoundException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class NotificationService {

    @Inject
    UserRepo userRepo;
    @Inject
    private NotificationRepo notiRepo;

    public PageResponseDTO<Notification> getNotifications(UUID currentUserId, int page, int size) {

        int pageIndex = Math.max(0, page);
        int pageSize = Math.min(Math.max(1, size), 50);

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<Notification> query = notiRepo.getNotification(currentUserId, pageable);

        List<Notification> items = query.stream().toList();

        return PageResponseDTO.of(items, query.page().index, query.page().size, query.count(), query.pageCount());
    }

    @Transactional
    public Notification createNortification(UUID currentUserId, NotificationDTO dto) {
        User author = userRepo.findByIdOptional(dto.actor_id)
                .orElseThrow(() -> new NotFoundException("User not found."));
        User receriver = userRepo.findByIdOptional(dto.receiver_id)
                .orElseThrow(() -> new NotFoundException("User not found."));
        if (!currentUserId.equals(author.getId())){
            throw new ForbiddenException("You are not allowed to perform this action.");
        }

        Notification notification = new Notification();
        notification.setReceiver_id(dto.receiver_id);
        notification.setActor_id(dto.actor_id);
        notification.setType(dto.type);
        notification.setPost_id(dto.post_id);
        notification.setComment_id(dto.comment_id);
        notification.set_read(false);
        notification.setCreated_at(LocalDateTime.now());

        notiRepo.persist(notification);
        return notification;
    }

    @Transactional
    public Notification updateNortification(UUID currentUserId, UpdateNotificationDTO dto) {
        Notification notification = notiRepo.findByIdOptional(dto.nortificationId)
                .orElseThrow(() -> new NotFoundException("Nortification not found."));
        if(!currentUserId.equals(notification.getReceiver_id())){
            throw new ForbiddenException("You are not allowed to perform this action.");
        }
        notification.set_read(dto.isRead);
        return notification;
    }

    @Transactional
    public List<Notification> deleteNortifications(UUID currentUserId, DeleteNotificationDTO dto) {
        List<Notification> result = new ArrayList<>();
        for (UUID targetId : dto.target) {

            Notification notification = notiRepo.findByIdOptional(targetId)
                    .orElseThrow(() ->
                            new NotFoundException("Nortification not found.")
                    );

            if (!currentUserId.equals(notification.getReceiver_id())) {
                throw new ForbiddenException(
                        "You are not allowed to perform this action."
                );
            }
            result.add(notification);
            notiRepo.delete(notification);
        }
        return result;
    }
}
