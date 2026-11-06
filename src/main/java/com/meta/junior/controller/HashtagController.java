package com.meta.junior.controller;

import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.social_media.hashtag.HashtagResponseDTO;
import com.meta.junior.service.HashtagService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/api/v1/hashtags")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class HashtagController {

    @Inject
    HashtagService hashtagService;

    @GET
    @Path("/trending")
    public Response getTrendingHashtags(@QueryParam("limit") @DefaultValue("10") int limit) {
        int safeLimit = Math.min(Math.max(1, limit), 50);
        List<HashtagResponseDTO> result = hashtagService.getTrendingHashtags(safeLimit);
        return Response.ok(ApiResponse.success("Lấy danh sách hashtag thịnh hành thành công", result)).build();
    }

    @GET
    @Path("/search")
    public Response searchHashtags(
            @QueryParam("query") String query,
            @QueryParam("limit") @DefaultValue("10") int limit) {
        int safeLimit = Math.min(Math.max(1, limit), 50);
        List<HashtagResponseDTO> result = hashtagService.searchHashtags(query, safeLimit);
        return Response.ok(ApiResponse.success("Tìm kiếm hashtag thành công", result)).build();
    }
}
