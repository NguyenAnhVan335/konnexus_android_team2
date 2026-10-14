package com.meta.junior.resource;

import com.meta.junior.dto.ApiResponse;
import com.meta.junior.dto.PageData;
import com.meta.junior.dto.post.PostCreateRequest;
import com.meta.junior.dto.post.PostDetailResponse;
import com.meta.junior.dto.post.PostResponse;
import com.meta.junior.dto.post.PostUpdateRequest;
import com.meta.junior.service.PostService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
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
    @Path("/trending")
    @Operation(summary = "List trending posts (ranked by interactions in the last N days)")
    public ApiResponse<PageData<PostResponse>> listTrendingPosts(
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size,
            @QueryParam("days") @DefaultValue("7") int days) {
        return ApiResponse.ok(
                postService.getTrendingPosts(page, size, days),
                "Lấy danh sách bài viết nổi bật thành công");
    }

    @GET
    @Path("/{id}")
    @Operation(summary = "Get a post by id (with reactions and comments)")
    public ApiResponse<PostDetailResponse> getPost(@PathParam("id") UUID id) {
        return ApiResponse.ok(postService.getPostById(id), "Lấy bài viết thành công");
    }

    /**
     * Updates a post, or soft deletes it when the body carries the status {@code DELETED}.
     *
     * <p>Deleting is expressed as a state change ({@code PUT}) instead of the former
     * {@code DELETE /api/v1/posts/{id}} verb:</p>
     * <pre>{ "status": "DELETED" }</pre>
     */
    @PUT
    @Path("/{id}")
    @Operation(summary = "Update a post, or soft delete it with status=DELETED")
    public ApiResponse<Object> updatePost(@PathParam("id") UUID id, @Valid PostUpdateRequest request) {
        if (request.isDeleteRequest()) {
            postService.deletePost(id);
            return ApiResponse.ok("Xóa bài viết thành công");
        }
        PostResponse data = postService.updatePost(id, request);
        return ApiResponse.<Object>ok(data, "Cập nhật bài viết thành công");
    }
}

