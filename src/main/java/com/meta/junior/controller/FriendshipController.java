package com.meta.junior.controller;

import com.meta.junior.dto.ApiResponse;
import com.meta.junior.dto.FriendshipDto;
import com.meta.junior.dto.FriendshipStatusDto;
import com.meta.junior.exception.ApiException;
import com.meta.junior.service.FriendshipService;
import io.quarkus.runtime.LaunchMode;
import jakarta.inject.Inject;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;
import java.util.UUID;

@Path("/api/friends")
@Produces(MediaType.APPLICATION_JSON)
public class FriendshipController {

    @Inject
    FriendshipService friendshipService;

    @POST
    @Path("/requests/{receiverId}")
    public Response sendRequest(@PathParam("receiverId") UUID receiverId,
            @HeaderParam("X-Test-User-Id") UUID testUserId) {
        var result = friendshipService.sendRequest(currentUserId(testUserId), receiverId);
        return Response.ok(ApiResponse.success(result.message(), result.friendship())).build();
    }

    // Một API GET trả cả lời mời đã gửi và đã nhận.
    @GET
    @Path("/requests")
    public Response getRequests(@HeaderParam("X-Test-User-Id") UUID testUserId) {
        FriendshipDto.RequestLists requests = friendshipService.getRequests(currentUserId(testUserId));
        return Response.ok(ApiResponse.success("Lấy danh sách lời mời kết bạn đã gửi và đã  thành công", requests))
                .build();
    }

    @PUT
    @Path("/requests/{requestId}/accept")
    public Response acceptRequest(@PathParam("requestId") UUID requestId,
            @HeaderParam("X-Test-User-Id") UUID testUserId) {
        FriendshipDto friendship = friendshipService.acceptRequest(currentUserId(testUserId), requestId);
        return Response.ok(ApiResponse.success("Đã xác nhận lời mời kết bạn", friendship)).build();
    }

    /** The receiver deletes a pending invitation (rejects it). */
    @DELETE
    @Path("/requests/{requestId}")
    public Response rejectRequest(@PathParam("requestId") UUID requestId,
            @HeaderParam("X-Test-User-Id") UUID testUserId) {
        friendshipService.rejectRequest(currentUserId(testUserId), requestId);
        return Response.ok(ApiResponse.<Void>success("Đã xóa lời mời kết bạn", null)).build();
    }

    /** The original sender can withdraw a still-pending invitation. */
    @DELETE
    @Path("/requests/{requestId}/cancel")
    public Response cancelRequest(@PathParam("requestId") UUID requestId,
            @HeaderParam("X-Test-User-Id") UUID testUserId) {
        friendshipService.cancelRequest(currentUserId(testUserId), requestId);
        return Response.ok(ApiResponse.<Void>success("Đã hủy lời mời kết bạn", null)).build();
    }

    @GET
    public Response getFriends(@HeaderParam("X-Test-User-Id") UUID testUserId) {
        List<FriendshipDto> friends = friendshipService.getFriends(currentUserId(testUserId));
        return Response.ok(ApiResponse.success("Lấy danh sách bạn bè thành công", friends)).build();
    }

    @GET
    @Path("/status/{otherUserId}")
    public Response getRelationshipStatus(@PathParam("otherUserId") UUID otherUserId,
            @HeaderParam("X-Test-User-Id") UUID testUserId) {
        FriendshipStatusDto status = friendshipService.getRelationshipStatus(currentUserId(testUserId), otherUserId);
        return Response.ok(ApiResponse.success("Lấy trạng thái quan hệ thành công", status)).build();
    }

    @DELETE
    @Path("/{friendId}")
    public Response unfriend(@PathParam("friendId") UUID friendId, @HeaderParam("X-Test-User-Id") UUID testUserId) {
        friendshipService.unfriend(currentUserId(testUserId), friendId);
        return Response.ok(ApiResponse.<Void>success("Đã hủy kết bạn", null)).build();
    }

    // Test-only identity. Never accept user-controlled identity in production.
    private UUID currentUserId(UUID testUserId) {
        if (LaunchMode.current() == LaunchMode.NORMAL) {
            throw new ApiException(403, "X-Test-User-Id chỉ được dùng khi chạy dev/test");
        }
        if (testUserId == null) {
            throw new ApiException(400, "Thiếu header X-Test-User-Id (UUID)");
        }
        return testUserId;
    }
}
