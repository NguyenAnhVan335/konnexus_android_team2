package alan.nguyen.repository;

import alan.nguyen.entity.Notification;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class NotificationRepo implements PanacheRepositoryBase<Notification, UUID> {
    public PanacheQuery<Notification> getNotification(UUID currentUserId, Page pageable) {
        return find("receiver_id = ?1 ORDER by created_at DESC",
                currentUserId)
                .page(pageable);
    }
}
