package alan.nguyen.repository;

import alan.nguyen.entity.MessageRead;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class MessageReadRepo implements PanacheRepositoryBase<MessageRead, UUID> {
}
