package com.meta.junior.controller;

import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.post.CreatePostRequestDTO;
import com.meta.junior.dto.social_media.post.PostResponseDTO;
import com.meta.junior.dto.social_media.post.UpdatePostRequestDTO;
import com.meta.junior.service.PostService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.UUID;

@Path("/api/v1/posts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class PostController {

    @Inject
    PostService postService;

    @Inject
    JsonWebToken jwt;

    /**
     * Tạo bài viết mới
     */
    @POST
    public Response createPost(@Valid @NotNull CreatePostRequestDTO dto) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PostResponseDTO result = postService.createPost(currentUserId, dto);
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.success("Đăng bài viết thành công", result))
                .build();
    }

    /**
     * Xem chi tiết một bài viết
     */
    @GET
    @Path("/{id}")
    public Response getPostDetail(@PathParam("id") UUID id) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PostResponseDTO result = postService.getPostDetail(currentUserId, id);
        return Response.ok(ApiResponse.success("Lấy thông tin bài viết thành công", result))
                .build();
    }

    /**
     * Lấy bảng tin (Newsfeed) có phân trang
     */
    @GET
    @Path("/feed")
    public Response getNewsfeed(
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size
    ) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PageResponseDTO<PostResponseDTO> result = postService.getNewsfeed(currentUserId, page, size);
        return Response.ok(ApiResponse.success("Lấy bảng tin thành công", result))
                .build();
    }

    /**
     * Lấy danh sách bài viết trên trang cá nhân của một người dùng
     */
    @GET
    @Path("/user/{userId}")
    public Response getUserTimeline(
            @PathParam("userId") UUID userId,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size
    ) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PageResponseDTO<PostResponseDTO> result = postService.getUserTimeline(currentUserId, userId, page, size);
        return Response.ok(ApiResponse.success("Lấy danh sách bài viết trang cá nhân thành công", result))
                .build();
    }

    /**
     * Cập nhật nội dung hoặc quyền riêng tư của bài viết (Chỉ tác giả)
     */
    @PUT
    @Path("/{id}")
    public Response updatePost(
            @PathParam("id") UUID id,
            @Valid @NotNull UpdatePostRequestDTO dto
    ) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PostResponseDTO result = postService.updatePost(currentUserId, id, dto);
        return Response.ok(ApiResponse.success("Cập nhật bài viết thành công", result))
                .build();
    }

    /**
     * Xóa mềm bài viết (Chỉ tác giả hoặc ADMIN)
     */
    @DELETE
    @Path("/{id}")
    public Response deletePost(@PathParam("id") UUID id) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        postService.deletePost(currentUserId, id);
        return Response.ok(ApiResponse.success("Đã xóa bài viết thành công", null))
                .build();
    }
}
