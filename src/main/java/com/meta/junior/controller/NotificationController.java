package alan.nguyen.controller;

import alan.nguyen.common.ApiResponse;
import alan.nguyen.dto.PageResponseDTO;
import alan.nguyen.dto.connexa.nortification.DeleteNotificationDTO;
import alan.nguyen.dto.connexa.nortification.NotificationDTO;
import alan.nguyen.dto.connexa.nortification.UpdateNotificationDTO;
import alan.nguyen.entity.Notification;
import alan.nguyen.service.NotificationService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.List;
import java.util.UUID;

@Path("/api/v1/nortifications")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class NotificationController {

    @Inject
    private JsonWebToken jwt;

    @Inject
    private NotificationService nortiService;

    @GET
    public Response getNotifications (
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size
    ){
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PageResponseDTO<Notification> notifications =  nortiService.getNotifications(currentUserId, page, size);
        return Response.ok(ApiResponse.success(notifications)).build();
    }

    @POST
    public Response createNotification (NotificationDTO dto){
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        Notification result = nortiService.createNortification(currentUserId, dto);
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.success("Create nortification successfully.", result))
                .build();
    }

    @PUT
    public Response updateNotification(UpdateNotificationDTO dto){
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        Notification result = nortiService.updateNortification(currentUserId, dto);
        return Response.ok(ApiResponse.success("Update nortification successfully.", result))
                .build();
    }

    @DELETE
    public Response deleteNotification (DeleteNotificationDTO dto){
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        List<Notification> result = nortiService.deleteNortifications(currentUserId, dto);
        return Response.ok(ApiResponse.success("Delete notifications successfully.", result))
                .build();
    }
}
