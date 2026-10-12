package com.meta.junior.resource;

import com.meta.junior.dto.ApiResponse;
import com.meta.junior.dto.PageData;
import com.meta.junior.dto.post.PostResponse;
import com.meta.junior.service.PostService;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;

import java.util.UUID;

@Path("/api/v1/users/{userId}/posts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Tag(name = "Post", description = "Post management")
public class UserPostsResource {

    @Inject
    PostService postService;

    @GET
    @Operation(summary = "List posts of a user (newest first)")
    public ApiResponse<PageData<PostResponse>> listUserPosts(
            @PathParam("userId") UUID userId,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size) {
        return ApiResponse.ok(
                postService.getPostsByUser(userId, page, size),
                "Lấy danh sách bài viết của người dùng thành công");
    }
}

