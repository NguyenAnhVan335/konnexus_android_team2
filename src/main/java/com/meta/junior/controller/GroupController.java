package com.meta.junior.controller;

import com.meta.junior.dto.*;
import com.meta.junior.common.ApiResponse;
import com.meta.junior.service.GroupService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;
import org.eclipse.microprofile.openapi.annotations.security.SecurityScheme;
import org.eclipse.microprofile.openapi.annotations.security.SecurityRequirement;
import org.eclipse.microprofile.openapi.annotations.enums.SecuritySchemeType;
import org.eclipse.microprofile.openapi.annotations.enums.SecuritySchemeIn;

// OpenAPI khai báo header để Swagger hiện nút Authorize.
@SecurityScheme(
        securitySchemeName = "KonnexusGroupTestHeader",
        type = SecuritySchemeType.APIKEY,
        in = SecuritySchemeIn.HEADER,
        apiKeyName = "X-Test-User-Id",
        description = "UUID dùng để giả lập người dùng khi chạy dev/test; không dùng ở production"
)
@SecurityRequirement(name = "KonnexusGroupTestHeader")
@Path("/api/groups")
@Produces(MediaType.APPLICATION_JSON)
public class GroupController {
    @Inject GroupService service;

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response create(@Valid CreateGroupRequest request) {
        return Response.status(Response.Status.CREATED)
                .entity(ApiResponse.success("Tạo nhóm thành công", service.create(request)))
                .build();
    }

    @GET
    public Response search(@QueryParam("keyword") String keyword) {
        return Response.ok(ApiResponse.success("Lấy danh sách nhóm thành công",
                service.search(keyword))).build();
    }

    @GET @Path("/mine")
    public Response mine() {
        return Response.ok(ApiResponse.success("Lấy danh sách nhóm đã tham gia thành công",
                service.mine())).build();
    }

    @GET @Path("/{groupId}")
    public Response detail(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy thông tin nhóm thành công",
                service.detail(groupId))).build();
    }

    @PUT @Path("/{groupId}")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response update(@PathParam("groupId") UUID groupId, @Valid UpdateGroupRequest request) {
        return Response.ok(ApiResponse.success("Cập nhật nhóm thành công",
                service.update(groupId, request))).build();
    }

    @PUT @Path("/{groupId}/delete")
    public Response delete(@PathParam("groupId") UUID groupId) {
        service.delete(groupId);
        return Response.ok(ApiResponse.success("Đã xóa mềm nhóm", null)).build();
    }

    @POST @Path("/{groupId}/join")
    public Response join(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Đã xử lý yêu cầu tham gia nhóm",
                service.join(groupId))).build();
    }

    @GET @Path("/{groupId}/membership")
    public Response membership(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy trạng thái thành viên thành công",
                service.status(groupId))).build();
    }

    @DELETE @Path("/{groupId}/join")
    public Response cancelJoin(@PathParam("groupId") UUID groupId) {
        service.cancelJoinRequest(groupId);
        return Response.ok(ApiResponse.success("Đã hủy yêu cầu tham gia", null)).build();
    }

    @GET @Path("/{groupId}/requests")
    public Response requests(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy danh sách yêu cầu thành công",
                service.pendingRequests(groupId))).build();
    }

    @PUT @Path("/{groupId}/requests/{requestId}/approve")
    public Response approve(@PathParam("groupId") UUID groupId, @PathParam("requestId") UUID requestId) {
        return Response.ok(ApiResponse.success("Đã duyệt thành viên",
                service.approve(groupId, requestId))).build();
    }

    @PUT @Path("/{groupId}/requests/{requestId}/reject")
    public Response reject(@PathParam("groupId") UUID groupId, @PathParam("requestId") UUID requestId) {
        service.reject(groupId, requestId);
        return Response.ok(ApiResponse.success("Đã từ chối yêu cầu tham gia", null)).build();
    }

    @GET @Path("/{groupId}/members")
    public Response members(@PathParam("groupId") UUID groupId) {
        return Response.ok(ApiResponse.success("Lấy danh sách thành viên thành công",
                service.listMembers(groupId))).build();
    }

    @DELETE @Path("/{groupId}/members/me")
    public Response leave(@PathParam("groupId") UUID groupId) {
        service.leave(groupId);
        return Response.ok(ApiResponse.success("Đã rời nhóm", null)).build();
    }

    @DELETE @Path("/{groupId}/members/{userId}")
    public Response removeMember(@PathParam("groupId") UUID groupId, @PathParam("userId") UUID target) {
        service.removeMember(groupId, target);
        return Response.ok(ApiResponse.success("Đã xóa thành viên khỏi nhóm", null)).build();
    }

    @PUT @Path("/{groupId}/members/{userId}/promote")
    public Response promote(@PathParam("groupId") UUID groupId, @PathParam("userId") UUID target) {
        return Response.ok(ApiResponse.success("Đã bổ nhiệm quản trị viên",
                service.changeAdmin(groupId, target, true))).build();
    }

    @PUT @Path("/{groupId}/members/{userId}/demote")
    public Response demote(@PathParam("groupId") UUID groupId, @PathParam("userId") UUID target) {
        return Response.ok(ApiResponse.success("Đã hạ quyền quản trị viên",
                service.changeAdmin(groupId, target, false))).build();
    }

    @PUT @Path("/{groupId}/owner/{userId}")
    public Response transferOwner(@PathParam("groupId") UUID groupId, @PathParam("userId") UUID target) {
        return Response.ok(ApiResponse.success("Đã chuyển quyền chủ nhóm",
                service.transferOwnership(groupId, target))).build();
    }
}
