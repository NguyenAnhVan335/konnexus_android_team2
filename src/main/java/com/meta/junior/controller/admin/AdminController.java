package alan.nguyen.controller.admin;

import alan.nguyen.service.ConversationService;
import alan.nguyen.service.UserService;
import alan.nguyen.service.MessageService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import io.quarkus.security.Authenticated;
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
        response.put("totalRooms", conversationService.countAllConversations());
        response.put("totalMessagesToday", messageService.countMessagesToday());

        response.put("isBotEnabled", isCharlesEnabled);
        response.put("botTokensUsed", charlesTokensUsed);

        // 2. Tạo dữ liệu giả lập cho biểu đồ 7 ngày (Bạn có thể Query DB group by Date thật sau)
        ArrayNode chartData = objectMapper.createArrayNode();
        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM");
        
        // Tạo data lùi về 7 ngày trước
        int[] dummyMessages = {120, 250, 180, 400, 310, 560, (int) messageService.countMessagesToday()};
        for (int i = 6; i >= 0; i--) {
            ObjectNode dayNode = objectMapper.createObjectNode();
            dayNode.put("date", today.minusDays(i).format(formatter));
            dayNode.put("messages", dummyMessages[6 - i]);
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