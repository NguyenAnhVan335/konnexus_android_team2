package com.meta.junior.controller;

import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.friendship.FriendshipRequestDTO;
import com.meta.junior.dto.social_media.friendship.FriendshipResponseDTO;
import com.meta.junior.entity.User;
import com.meta.junior.service.FriendshipService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.UUID;

@Path("/api/friends")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class FriendshipController {

    @Inject
    FriendshipService friendshipService;

    @Inject
    JsonWebToken jwt;

    @POST
    @Path("/requests")
    public Response sendRequest(FriendshipRequestDTO dto) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        FriendshipResponseDTO result = friendshipService.sendRequest(currentUserId, dto);
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.success("Gửi lời mời kết bạn thành công", result))
                .build();
    }

    @GET
    public Response getFriends(
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("20") int size) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PageResponseDTO<User> result = friendshipService.getAllFriends(currentUserId, page, size);
        return Response.ok(ApiResponse.success("Lấy danh sách bạn bè thành công", result)).build();
    }

    @PUT
    @Path("/requests/{requestId}/accept")
    public Response acceptRequest(@PathParam("requestId") UUID requestId) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        FriendshipResponseDTO result = friendshipService.acceptRequest(currentUserId, requestId);
        return Response.ok(ApiResponse.success("Đã chấp nhận lời mời kết bạn", result)).build();
    }

    @PUT
    @Path("/requests/{requestId}/reject")
    public Response rejectRequest(@PathParam("requestId") UUID requestId) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        FriendshipResponseDTO result = friendshipService.rejectRequest(currentUserId, requestId);
        return Response.ok(ApiResponse.success("Đã từ chối lời mời kết bạn", result)).build();
    }

    @DELETE
    @Path("/{friendId}")
    public Response unfriend(@PathParam("friendId") UUID friendId) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        friendshipService.deleteRelationship(currentUserId, friendId);
        return Response.ok(ApiResponse.success("Đã hủy kết bạn", null)).build();
    }
}
