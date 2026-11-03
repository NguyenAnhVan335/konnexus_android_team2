package com.meta.junior.controller;

import com.meta.junior.dto.*;
import com.meta.junior.common.ApiResponse;
import com.meta.junior.service.GroupPostService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;
import org.eclipse.microprofile.openapi.annotations.security.SecurityRequirement;

@SecurityRequirement(name = "KonnexusGroupTestHeader")
@Path("/api/groups/{groupId}/posts")
@Produces(MediaType.APPLICATION_JSON)
public class GroupPostController {
    @Inject GroupPostService service;

    @GET
    public Response list(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy danh sách bài viết thành công",
                service.published(groupId))).build();
    }

    @GET @Path("/pending")
    public Response pending(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy danh sách bài chờ duyệt thành công",
                service.pending(groupId))).build();
    }

    @GET @Path("/mine")
    public Response mine(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy bài viết của tôi thành công",
                service.mine(groupId))).build();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@PathParam("groupId") UUID groupId, @Valid CreateGroupPostRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.success("Tạo bài viết thành công",
                        service.create(groupId, request))).build();
    }

    @PUT @Path("/{postId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response edit(@PathParam("groupId") UUID groupId, @PathParam("postId") UUID postId,
                         @Valid CreateGroupPostRequest request) {
        return Response.ok(ApiResponse.success("Cập nhật bài viết thành công",
                service.update(groupId, postId, request))).build();
    }

    @PUT @Path("/{postId}/approve")
    public Response approve(@PathParam("groupId") UUID groupId, @PathParam("postId") UUID postId) {
        return Response.ok(ApiResponse.success("Đã duyệt bài viết",
                service.moderate(groupId, postId, true))).build();
    }

    @PUT @Path("/{postId}/reject")
    public Response reject(@PathParam("groupId") UUID groupId, @PathParam("postId") UUID postId) {
        return Response.ok(ApiResponse.success("Đã từ chối bài viết",
                service.moderate(groupId, postId, false))).build();
    }

    @PUT @Path("/{postId}/delete")
    public Response delete(@PathParam("groupId") UUID groupId, @PathParam("postId") UUID postId) {
        service.delete(groupId, postId);
        return Response.ok(ApiResponse.success("Đã xóa mềm bài viết", null)).build();
    }
}
