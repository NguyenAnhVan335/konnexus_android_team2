package com.meta.junior.controller.admin;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.meta.junior.repository.PostRepo;
import com.meta.junior.service.ConversationService;
import com.meta.junior.service.MessageService;
import com.meta.junior.service.UserService;
import jakarta.annotation.security.RolesAllowed;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.UUID;

@Path("/api/admin")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@RolesAllowed("ADMIN")
public class AdminController {

    @Inject
    UserService userService;

    @Inject
    MessageService messageService;

    @Inject
    ConversationService conversationService;

    @Inject
    PostRepo postRepo;

    @Inject
    ObjectMapper objectMapper;

    // Biến tạm lưu trạng thái Bot (Trong thực tế nên lưu vào Database bảng `SystemConfig`)
    private static boolean isCharlesEnabled = true;
    private static long charlesTokensUsed = 15420; // Giả lập số lượng token đã dùng

    public static boolean isBotActive() {
        return isCharlesEnabled;
    }

    @GET
    @Path("/dashboard")
    public Response getDashboardData() {
        ObjectNode response = objectMapper.createObjectNode();

        response.put("totalUsers", userService.countAllUsers());
        response.put("onlineUsers", userService.countOnlineUsers());
        response.put("totalPosts", postRepo.count("isDeleted = false"));
        response.put("totalMessages", messageService.countAllMessages());
        response.put("totalMessagesToday", messageService.countMessagesToday());
        response.put("totalRooms", conversationService.countAllConversations());

        response.put("isBotEnabled", isCharlesEnabled);
        response.put("botTokensUsed", charlesTokensUsed);

        // Backend chưa lưu phiên làm việc nên KHÔNG bịa "số giờ sử dụng": trả null
        // để frontend hiển thị "Chưa có dữ liệu".
        response.putNull("totalUsageHours");

        // Biểu đồ 7 ngày dùng dữ liệu thật (đếm tin nhắn theo ngày), thay cho số giả lập.
        ArrayNode chartData = objectMapper.createArrayNode();
        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");
        Map<LocalDate, Long> messagesByDay = messageService.countMessagesByDay(7);
        for (int i = 6; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            ObjectNode dayNode = objectMapper.createObjectNode();
            dayNode.put("date", day.format(formatter));
            dayNode.put("messages", messagesByDay.getOrDefault(day, 0L));
            chartData.add(dayNode);
        }
        response.set("chartData", chartData);

        return Response.ok(response).build();
    }

    @POST
    @Path("/bot/toggle")
    public Response toggleBot(Map<String, Boolean> request) {
        if (request.containsKey("enabled")) {
            isCharlesEnabled = request.get("enabled");
            return Response.ok().build();
        }
        return Response.status(Response.Status.BAD_REQUEST).build();
    }

    @GET
    @Path("/users/list")
    public Response getManageUsers() {
        return Response.ok(userService.getAll()).build();
    }

    @DELETE
    @Path("/users/{id}")
    public Response deleteUserByAdmin(@PathParam("id") UUID userId) {
        userService.anonymizeUser(userId);
        return Response.ok("Đã xóa người dùng thành công").build();
    }

    @GET
    @Path("/rooms/list")
    public Response getManageRooms() {
        return Response.ok(conversationService.getAllRooms()).build();
    }

    @DELETE
    @Path("/rooms/{id}")
    public Response deleteRoomByAdmin(@PathParam("id") UUID conversation_id) {
        conversationService.deleteGroup(conversation_id);
        return Response.ok().build();
    }
}