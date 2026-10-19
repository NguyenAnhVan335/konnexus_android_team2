package com.meta.junior.controller;

import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.CommentResponseDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.CreateCommentRequestDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.ReactionRequestDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.ReactionUserResponseDTO;
import com.meta.junior.service.PostInteractionService;
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
public class PostInteractionController {

    @Inject
    PostInteractionService interactionService;

    @Inject
    JsonWebToken jwt;

    /**
     * Thả, đổi hoặc hủy biểu cảm bài viết
     */
    @POST
    @Path("/{postId}/reactions")
    public Response toggleReaction(
            @PathParam("postId") UUID postId,
            @Valid @NotNull ReactionRequestDTO dto
    ) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        interactionService.toggleReaction(currentUserId, postId, dto);
        return Response.ok(ApiResponse.success("Thực hiện tương tác thành công", null)).build();
    }

    /**
     * Tạo mới một bình luận trên bài viết
     */
    @POST
    @Path("/{postId}/comments")
    public Response createComment(
            @PathParam("postId") UUID postId,
            @Valid @NotNull CreateCommentRequestDTO dto
    ) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        CommentResponseDTO result = interactionService.createComment(currentUserId, postId, dto);
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.success("Bình luận thành công", result))
                .build();
    }

    /**
     * Lấy danh sách bình luận của bài viết có phân trang
     */
    @GET
    @Path("/{postId}/comments")
    public Response getPostComments(
            @PathParam("postId") UUID postId,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size
    ) {
        PageResponseDTO<CommentResponseDTO> result = interactionService.getPostComments(postId, page, size);
        return Response.ok(ApiResponse.success("Lấy danh sách bình luận thành công", result)).build();
    }

    /**
     * Xóa mềm bình luận (Chỉ tác giả bình luận hoặc chủ bài viết)
     */
    @DELETE
    @Path("/comments/{commentId}")
    public Response deleteComment(@PathParam("commentId") UUID commentId) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        interactionService.deleteComment(currentUserId, commentId);
        return Response.ok(ApiResponse.success("Đã xóa bình luận thành công", null)).build();
    }

    /**
     * Lấy danh sách Reaction của bài viết có phân trang
     */
    @GET
    @Path("/{postId}/reactions")
    public Response getPostReactions(
            @PathParam("postId") UUID postId,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("20") int size) {

        PageResponseDTO<ReactionUserResponseDTO> response = interactionService.getPostReactions(postId, page, size);
        return Response.ok(ApiResponse.success(response)).build();
    }
}