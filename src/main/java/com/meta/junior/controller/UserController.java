package com.meta.junior.controller;
import com.meta.junior.common.ApiResponse;
import com.meta.junior.dto.UpdateProfileDTO;
import com.meta.junior.dto.UserDTO;
import com.meta.junior.entity.User;
import com.meta.junior.service.UserSearchService;
import com.meta.junior.service.UserService;
import io.quarkus.security.Authenticated;
import jakarta.annotation.security.PermitAll;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.jwt.JsonWebToken;

import java.util.List;
import java.util.UUID;


@Path("/api/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@Authenticated
public class UserController {

    @Inject
    UserService userService;

    @Inject
    JsonWebToken jwt;

    @Inject
    UserSearchService userSearchService;

    @GET
    @Authenticated
    public Response getAll(){
            List<User> list = userService.getAll();
            return Response.ok(list).build();
    }
    @PUT
    @Path("/{id}")
    @Authenticated
    public Response updateUser(@PathParam("id") UUID id, UpdateProfileDTO dto){
            return userService.updateUser(id, dto);
    }

    @POST
    @PermitAll
    public Response addUser(UserDTO dto){
            return userService.addUser(dto);
    }
    @DELETE
    @Path("/{id}")
    @RolesAllowed("ADMIN")
    public Response deleteUser(@PathParam("id") UUID id){
            return userService.deleteUser(id);
    }

    @GET
    @Path("/search")
    public Response searchUsers(@QueryParam("keyword") String keyword){
            UUID currentUserId = UUID.fromString(jwt.getSubject());
            return Response.ok(ApiResponse.success("Tìm kiếm người dùng thành công", userSearchService.search(keyword, currentUserId))).build();
    }

    /** Cập nhật trạng thái online/offline của người dùng hiện tại. */
    @PUT
    @Path("/status")
    public Response updateStatus(@QueryParam("online") boolean online){
            UUID currentUserId = UUID.fromString(jwt.getSubject());
            userService.updateUserStatus(currentUserId, online);
            return Response.ok(ApiResponse.success("Đã cập nhật trạng thái hoạt động", null)).build();
    }

}

