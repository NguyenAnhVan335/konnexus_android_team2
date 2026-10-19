package com.meta.junior.controller;
import com.meta.junior.dto.chat.conversation.AddMemberRequestDTO;
import com.meta.junior.dto.chat.conversation.CreateGroupRequestDTO;
import com.meta.junior.dto.chat.conversation.MemberResponseDTO;
import com.meta.junior.dto.chat.conversation.UpdateConvDTO;
import com.meta.junior.dto.chat.user.PromotingRoleDTO;
import com.meta.junior.service.ConversationService;
import com.meta.junior.service.ParticipantService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Path("/api/conversations")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class ConversationController {

    @Inject
    ConversationService conversationService;

    @Inject
    JsonWebToken jwt;

    @Inject
    ParticipantService participantService;

    @POST
    @Authenticated
    public Response createGroupChat(CreateGroupRequestDTO dto){
        UUID creator_id = UUID.fromString(jwt.getSubject());
        try {
            return conversationService.createGroupChat(creator_id, dto.title, dto.memberIds, dto.avatar_url);
        } catch (Exception e) {
            return Response.status(500)
                    .entity(
                            Map.of("message", e.getMessage())
                    )
                    .build();
        }
    }
    @GET
    @Authenticated
    public Response getMyConversations(){
        UUID myId = UUID.fromString(jwt.getSubject());
        try {
            return Response.ok(conversationService.getUserConversations(myId)).build();
        }catch (Exception e) {
            return Response.status(500)
                    .entity(
                            Map.of("message", e.getMessage())
                    )
                    .build();
        }
    }

    @GET
    @Path("/{id}/online-users")
    @Authenticated
    public Response getOnlineUsers(@PathParam("id") UUID conversationId){
        List<UUID> onlineUserIds = conversationService.getOnlineUsersId(conversationId);

        return Response.ok(onlineUserIds).build();
    }

    //Get participants in conversation
    @GET
    @Path("/{id}/members")
    @Authenticated
    public Response getMembers(@PathParam("id") UUID conversationId){
        List<MemberResponseDTO> members = participantService.getMembers(conversationId);

        return Response.ok(members).build();
    }

    @PUT
    @Path(("/{id}"))
    @Authenticated
    public Response updateConv(@PathParam("id") UUID conversation_id, UpdateConvDTO dto){
        return conversationService.updateConv(conversation_id, dto);
    }


    //Promoting user's role
    @PUT
    @Path("/{id}/members/{user_id}/role")
    @Authenticated
    public Response promotingRole(
            @PathParam("id") UUID conversation_id,
            @PathParam("user_id") UUID user_id,
            PromotingRoleDTO dto
            ){
        long updated_row = participantService.promotingRole(conversation_id, user_id, dto.role);
        if(updated_row==0)
            return Response.serverError().build();
        return Response.ok(
                Map.of(
                        "updated_row",
                        updated_row
                )
        ).build();
    }

    //kick user out of group
    @DELETE
    @Path("/{id}/members/{user_id}")
    @Authenticated
    public Response kickUser(
            @PathParam("id") UUID conversation_id,
            @PathParam("user_id") UUID user_id
    ){
        long deleted_row = participantService.kickUser(conversation_id, user_id);
        if(deleted_row==0)
            return Response.serverError().build();
        return Response.ok(
                Map.of(
                        "deleted_row",
                        deleted_row
                )
        ).build();
    }

    @DELETE
    @Path("/{id}")
    @Authenticated
    public Response deleteGroup(@PathParam("id") UUID conversation_id){
        return conversationService.deleteGroup(conversation_id);
    }

    //Add member to conversation
    @POST
    @Path("/{id}/members")
    @Authenticated
    public Response addMember(
            @PathParam("id") UUID conversation_id,
            AddMemberRequestDTO dto
    ){
        return participantService.addMember(conversation_id, dto.memberIds);
    }

}
