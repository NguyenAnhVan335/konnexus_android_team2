package alan.nguyen.repository;

import alan.nguyen.entity.Message;
import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class MessageRepo implements PanacheRepositoryBase<Message, UUID> {
}
