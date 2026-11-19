package com.meta.junior.controller;

import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.social_media.activity.ActivityLogResponseDTO;
import com.meta.junior.service.ActivityLogService;
import io.quarkus.security.Authenticated;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.List;
import java.util.UUID;

/**
 * Lịch sử hoạt động của chính người dùng đang đăng nhập.
 */
@Path("/api/activities")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class ActivityLogController {

    @Inject
    ActivityLogService activityLogService;

    @Inject
    JsonWebToken jwt;

    /**
     * GET /api/activities?from=...&to=...
     *
     * <p>Mặc định trả hoạt động trong 7 ngày gần nhất, sắp xếp mới nhất trước.
     * `from`/`to` nhận ISO-8601 (`2026-11-11T00:00:00`) hoặc riêng ngày
     * (`2026-11-11`).</p>
     */
    @GET
    public Response getActivities(
            @QueryParam("from") String from,
            @QueryParam("to") String to) {
        UUID currentUserId = UUID.fromString(jwt.getSubject());
        List<ActivityLogResponseDTO> result = activityLogService.getActivities(currentUserId, from, to);
        return Response.ok(ApiResponse.success("Lấy lịch sử hoạt động thành công", result)).build();
    }
}
