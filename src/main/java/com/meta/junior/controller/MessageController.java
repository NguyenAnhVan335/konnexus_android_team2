package alan.nguyen.controller;

import alan.nguyen.dto.chatify.message.MessageRequestDTO;
import alan.nguyen.entity.Message;
import alan.nguyen.service.MessageService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.List;
import java.util.UUID;

@Path("/api/messages")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class MessageController {

    @Inject
    MessageService messageService;

    @Inject
    JsonWebToken jwt;

    @GET
    @Path("/{conversation_id}")
    public Response getMessages(
            @PathParam("conversation_id") UUID conversation_id,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("50") int size
    ){
        UUID user_id = UUID.fromString(jwt.getSubject());
        List<Message> messages = messageService.getMessages(conversation_id, user_id, page, size);
        return Response.ok(messages).build();
    }

    @POST
    public Response sendMessage(MessageRequestDTO request) {
        UUID senderId = UUID.fromString(jwt.getSubject());
        Message savedMsg = messageService.sendMessage(senderId, request.conversation_id, request.content, request.attachment_url);
        return Response.status(Response.Status.CREATED).entity(savedMsg).build();
    }

    @GET
    @Path("/recent/{id}")
    public Response getRecentMessage(@PathParam("id") UUID conversation_id){
        return Response.ok(messageService.getRecentMessages(conversation_id)).build();
    }
}
