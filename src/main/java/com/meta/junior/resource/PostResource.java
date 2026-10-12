package com.meta.junior.resource;

import com.meta.junior.dto.ApiResponse;
import com.meta.junior.dto.PageData;
import com.meta.junior.dto.post.PostCreateRequest;
import com.meta.junior.dto.post.PostResponse;
import com.meta.junior.dto.post.PostUpdateRequest;
import com.meta.junior.service.PostService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.net.URI;
import java.util.UUID;

@Path("/api/v1/posts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Post", description = "Post management")
public class PostResource {

    @Inject
    PostService postService;

    @POST
    @Operation(summary = "Create a post")
    public Response createPost(@Valid PostCreateRequest request) {
        PostResponse data = postService.createPost(request);
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.ok(data, "Đăng bài viết thành công"))
                .location(URI.create("/api/v1/posts/" + data.id()))
                .build();
    }

    @GET
    @Operation(summary = "List posts (newest first)")
    public ApiResponse<PageData<PostResponse>> listPosts(
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size) {
        return ApiResponse.ok(postService.getPosts(page, size), "Lấy danh sách bài viết thành công");
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Get a post by id")
    public ApiResponse<PostResponse> getPost(@PathParam("id") UUID id) {
        return ApiResponse.ok(postService.getPostById(id), "Lấy bài viết thành công");
    }

    @PUT
    @Path("/{id}")
    @Operation(summary = "Update a post")
    public ApiResponse<PostResponse> updatePost(@PathParam("id") UUID id, @Valid PostUpdateRequest request) {
        return ApiResponse.ok(postService.updatePost(id, request), "Cập nhật bài viết thành công");
    }

    @DELETE
    @Path("/{id}")
    @Operation(summary = "Delete a post (soft delete)")
    public ApiResponse<Void> deletePost(@PathParam("id") UUID id) {
        postService.deletePost(id);
        return ApiResponse.ok("Xóa bài viết thành công");
    }
}

