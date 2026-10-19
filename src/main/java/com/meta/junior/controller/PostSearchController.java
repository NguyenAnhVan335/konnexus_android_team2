package com.meta.junior.controller;


import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.post.PostResponseDTO;
import com.meta.junior.service.PostSearchService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.Collections;
import java.util.UUID;

@Path("/api/v1/posts")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class PostSearchController {

    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 30;
    private static final int MAX_KEYWORD_LENGTH = 200;
    private static final int MAX_TAG_LENGTH = 100;

    @Inject
    PostSearchService postSearchService;

    @Inject
    JsonWebToken jwt;

    /**
     * Tìm kiếm bài viết theo từ khóa nội dung có phân trang và lọc privacy
     */
    @GET
    @Path("/search")
    public Response searchByKeyword(
            @QueryParam("keyword") String keyword,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("20") int size
    ) {
        Response paginationError = validatePagination(page, size);
        if (paginationError != null) {
            return paginationError;
        }

        if (keyword != null && keyword.trim().length() > MAX_KEYWORD_LENGTH) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(ApiResponse.error("Từ khóa tìm kiếm không được vượt quá " + MAX_KEYWORD_LENGTH + " ký tự"))
                    .build();
        }

        if (keyword == null || keyword.trim().isEmpty()) {
            return Response.ok(ApiResponse.success(
                    "Tìm kiếm bài viết thành công",
                    PageResponseDTO.of(Collections.emptyList(), page, size, 0, 0)
            )).build();
        }

        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PageResponseDTO<PostResponseDTO> result = postSearchService.searchByKeyword(currentUserId, keyword, page, size);
        return Response.ok(ApiResponse.success("Tìm kiếm bài viết thành công", result)).build();
    }

    /**
     * Tìm kiếm danh sách bài viết gắn hashtag cụ thể có phân trang và lọc privacy
     */
    @GET
    @Path("/tags/{tagName}")
    public Response searchByHashtag(
            @PathParam("tagName") String tagName,
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("20") int size
    ) {
        Response paginationError = validatePagination(page, size);
        if (paginationError != null) {
            return paginationError;
        }

        if (tagName != null && tagName.trim().length() > MAX_TAG_LENGTH) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(ApiResponse.error("Hashtag không được vượt quá " + MAX_TAG_LENGTH + " ký tự"))
                    .build();
        }

        String cleanTag = tagName != null ? tagName.trim() : "";
        if (cleanTag.startsWith("#")) {
            cleanTag = cleanTag.substring(1).trim();
        }
        if (cleanTag.isEmpty()) {
            return Response.ok(ApiResponse.success(
                    "Lấy danh sách bài viết theo hashtag thành công",
                    PageResponseDTO.of(Collections.emptyList(), page, size, 0, 0)
            )).build();
        }

        UUID currentUserId = UUID.fromString(jwt.getSubject());
        PageResponseDTO<PostResponseDTO> result = postSearchService.searchByHashtag(currentUserId, tagName, page, size);
        return Response.ok(ApiResponse.success("Lấy danh sách bài viết theo hashtag thành công", result)).build();
    }

    private Response validatePagination(int page, int size) {
        if (page < 0) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(ApiResponse.error("Số trang (page) phải lớn hơn hoặc bằng 0"))
                    .build();
        }
        if (size < 1 || size > MAX_PAGE_SIZE) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(ApiResponse.error("Kích thước trang (size) phải nằm trong khoảng từ 1 đến " + MAX_PAGE_SIZE))
                    .build();
        }
        return null;
    }
}
