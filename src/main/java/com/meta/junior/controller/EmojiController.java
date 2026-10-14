
package com.meta.junior.controller;

import java.util.List;
import java.util.UUID;

import com.meta.junior.dto.EmojiRequest;
import com.meta.junior.dto.EmojiResponse;
import com.meta.junior.service.EmojiService;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/api/emojis")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class EmojiController {

    @Inject
    EmojiService emojiService;

    // Thêm, đổi hoặc gỡ emoji
    @POST
    public EmojiResponse toggle(EmojiRequest request) {
        return emojiService.toggle(request);
    }

    // Lấy emoji theo bài viết
    @GET
    @Path("/post/{postId}")
    public List<EmojiResponse> getByPostId(
            @PathParam("postId") UUID postId) {
        return emojiService.getByPostId(postId);
    }

    // Lấy emoji theo bình luận
    @GET
    @Path("/comment/{commentId}")
    public List<EmojiResponse> getByCommentId(
            @PathParam("commentId") UUID commentId) {
        return emojiService.getByCommentId(commentId);
    }

    // Lấy emoji theo ID
    @GET
    @Path("/{id}")
    public EmojiResponse getById(
            @PathParam("id") UUID id) {
        return emojiService.getById(id);
    }

    // Cập nhật emoji theo ID
    @PUT
    @Path("/{id}")
    public EmojiResponse update(
            @PathParam("id") UUID id,
            EmojiRequest request) {
        return emojiService.update(id, request);
    }

    // Xóa emoji theo ID
    @DELETE
    @Path("/{id}")
    public Response delete(@PathParam("id") UUID id) {
        emojiService.delete(id);
        return Response.noContent().build();
    }
}
