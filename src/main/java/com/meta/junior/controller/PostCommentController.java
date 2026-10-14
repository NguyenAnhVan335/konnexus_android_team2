
package com.meta.junior.controller;

import java.util.UUID;

import com.meta.junior.dto.PostCommentRequest;
import com.meta.junior.entity.PostComment;
import com.meta.junior.service.PostCommentService;

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

@Path("/api/comments")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class PostCommentController {

    @Inject
    PostCommentService commentService;

    @POST
    public PostComment create(PostCommentRequest request) {
        PostComment comment = new PostComment();
        comment.postId = request.postId;
        comment.content = request.content;
        comment.image = request.image;
        comment.cmtId = request.cmtId;

        return commentService.create(comment);
    }

    @GET
    @Path("/post/{postId}")
    public Object getByPostId(@PathParam("postId") UUID postId) {
        return commentService.getByPostId(postId);
    }

    @GET
    @Path("/{id}")
    public PostComment getById(@PathParam("id") UUID id) {
        return commentService.getById(id);
    }

    @PUT
    @Path("/{id}")
    public PostComment update(
            @PathParam("id") UUID id,
            PostCommentRequest request) {

        PostComment comment = new PostComment();
        comment.content = request.content;
        comment.image = request.image;

        return commentService.update(id, comment);
    }

    @DELETE
    @Path("/{id}")
    public void delete(@PathParam("id") UUID id) {
        commentService.delete(id);
    }
}
