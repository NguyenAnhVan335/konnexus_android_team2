package alan.nguyen.service;

import alan.nguyen.common.GroupRole;
import alan.nguyen.dto.chatify.conversation.MemberResponseDTO;
import alan.nguyen.repository.ParticipantRepo;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class ParticipantService {

    @Inject
    ParticipantRepo participantRepo;

    public List<MemberResponseDTO> getMembers(UUID conversationId) {
        return participantRepo.getMembers(conversationId);
    }

    @Transactional
    public long promotingRole(UUID conversationId, UUID userId, GroupRole role) {
        return participantRepo.promotingRole(conversationId, userId, role);
    }

    @Transactional
    public long kickUser(UUID conversationId, UUID userId) {
        return participantRepo.kickUser(conversationId, userId);
    }

    @Transactional
    public Response addMember(UUID conversationId, List<UUID> memberIds) {
        return participantRepo.addMember(conversationId, memberIds);
    }
}
