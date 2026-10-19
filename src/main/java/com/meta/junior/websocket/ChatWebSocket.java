    package alan.nguyen.websocket;

    import alan.nguyen.controller.admin.AdminController;
    import alan.nguyen.dto.chatify.message.MessageRequestDTO;
    import alan.nguyen.dto.chatify.message.MessageResponseDTO;
    import alan.nguyen.entity.Message;
    import alan.nguyen.service.MessageReadService;
    import alan.nguyen.service.MessageService;
    import alan.nguyen.service.UserService;
    import alan.nguyen.service.chatbot.ChatbotService;
    import com.fasterxml.jackson.core.JsonProcessingException;
    import com.fasterxml.jackson.databind.ObjectMapper;
    import com.fasterxml.jackson.databind.node.ObjectNode;
    import io.quarkus.security.Authenticated;
    import io.quarkus.websockets.next.*;
    import jakarta.inject.Inject;
    import org.eclipse.microprofile.jwt.JsonWebToken;

    import java.util.List;
    import java.util.Map;
    import java.util.UUID;
    import java.util.concurrent.CompletableFuture;
    import java.util.concurrent.ConcurrentHashMap;

    @WebSocket(path = "/chat/{conversation_id}")
    @Authenticated
    public class ChatWebSocket {

        @Inject
        OpenConnections connections;

        @Inject
        UserService userService;

        @Inject
        MessageService messageService;

        @Inject
        MessageReadService msgReadService;

        @Inject
        ChatbotService chatbotService;

        @Inject
        JsonWebToken jwt;

        @Inject
        ObjectMapper objectMapper;

        // Dùng Map để nhớ connection nào của user nào
        private static final Map<String, String> connectionUserMap = new ConcurrentHashMap<>();

        @OnOpen
        public void onOpen(WebSocketConnection connection, @PathParam("conversation_id") String conversation_id){
            String userId = jwt.getSubject();

            connectionUserMap.put(connection.id(), userId);

            System.out.println("User ["+userId+"] joined the group chat!");
        }

        @OnTextMessage
        public void onMessage(MessageRequestDTO request, @PathParam("conversation_id") String conversation_id) throws JsonProcessingException {
            UUID senderId = UUID.fromString(jwt.getSubject());

            if(request.type.equals("TYPING")){
                String typing_json = "{\"type\":\"TYPING\", \"senderId\":\"" + senderId + "\"}";
                broadcastToRoom(UUID.fromString(conversation_id), typing_json);
                return;
            }

            if(request.type.equals("READ")){
                msgReadService.markAsRead(request.message_id, senderId);
                String read_json = "{\"type\":\"READ\", \"userId\":\"" + senderId + "\", \"message_id\":\"" + request.message_id + "\"}";
                broadcastToRoom(UUID.fromString(conversation_id), read_json);
                return;
            }

            Message saved_msg = messageService.sendMessage(senderId, UUID.fromString(conversation_id), request.content, request.attachment_url);

            ObjectNode userMsgNode = objectMapper.valueToTree(saved_msg);
            userMsgNode.put("type", "CHAT");
            broadcastToRoom(UUID.fromString(conversation_id), objectMapper.writeValueAsString(userMsgNode));

            if (request.content != null && request.content.toLowerCase().startsWith("@charles")) {

                if (!AdminController.isBotActive()) {
                    try {
                        String disableContent = "Trời nóng quá nên tôi đang nghỉ mát không tiện giúp bạn mất rùi. Thông cảm chút nhoa <3!";
                        ObjectNode disabledNode = objectMapper.createObjectNode();
                        disabledNode.put("type", "CHAT");
                        disabledNode.put("id", System.currentTimeMillis());
                        disabledNode.put("user_id", "2d61b0d1-1512-494b-ba1d-bf1c55de1173");
                        disabledNode.put("content", disableContent);
                        disabledNode.put("attachment_url", (String) null);

                        broadcastToRoom(UUID.fromString(conversation_id), objectMapper.writeValueAsString(disabledNode));

                        messageService.sendMessage(UUID.fromString("2d61b0d1-1512-494b-ba1d-bf1c55de1173"),
                                UUID.fromString(conversation_id),
                                disableContent,
                                null);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    return;
                }

                String prompt = request.content.substring(8).trim();

                String botTypingJson = "{\"type\":\"TYPING\", \"senderId\":\"bot_charles\"}";
                broadcastToRoom(UUID.fromString(conversation_id), botTypingJson);

                if(prompt.toLowerCase().contains("tóm tắt")){
                    List<MessageResponseDTO> recentMessages = messageService.getRecentMessages(UUID.fromString(conversation_id));

                    StringBuilder historyBuilder = new StringBuilder();
                    historyBuilder.append("Đây là lịch sử trò chuyện gần đây của nhóm:\n");

                    for(var msg : recentMessages){
                        String senderName = msg.username;
                        historyBuilder.append("- ")
                                .append(senderName)
                                .append(": ")
                                .append(msg.content)
                                .append("\n");
                    }
                    String finalChatHistory = historyBuilder.toString();
                    CompletableFuture.runAsync(() -> {
                        try {
                            // Gọi hàm summarize của AI Service
                            String aiSummary = chatbotService.summerize(finalChatHistory);

                            // Đóng gói JSON gửi trả về cho cả phòng chat
                            ObjectNode botMsgNode = objectMapper.createObjectNode();
                            botMsgNode.put("type", "CHAT");
                            botMsgNode.put("id", System.currentTimeMillis());
                            botMsgNode.put("user_id", "2d61b0d1-1512-494b-ba1d-bf1c55de1173");
                            botMsgNode.put("content", aiSummary); // Trả về bản tóm tắt
                            botMsgNode.put("attachment_url", (String) null);

                            broadcastToRoom(UUID.fromString(conversation_id), objectMapper.writeValueAsString(botMsgNode));

                            messageService.sendMessage(
                                    UUID.fromString("2d61b0d1-1512-494b-ba1d-bf1c55de1173"),
                                    UUID.fromString(conversation_id),
                                    aiSummary,
                                    null
                            );
                        } catch (Exception e) {
                            e.printStackTrace();
                            broadcastToRoom(UUID.fromString(conversation_id), "{\"type\":\"CHAT\", \"user_id\":\"bot_charles\", \"content\":\"Charles không đọc được lịch sử chat, thử lại sau nhé bạn hiền!\"}");
                        }
                    });
                }else{
                    CompletableFuture.runAsync(() -> {
                        try {
                            String aiResponse = chatbotService.ask(prompt);


                            ObjectNode botMsgNode = objectMapper.createObjectNode();
                            botMsgNode.put("type", "CHAT");
                            botMsgNode.put("id", System.currentTimeMillis()); // ID tạm thời
                            botMsgNode.put("user_id", "2d61b0d1-1512-494b-ba1d-bf1c55de1173");
                            botMsgNode.put("content", aiResponse);
                            botMsgNode.put("attachment_url", (String) null);

                            broadcastToRoom(UUID.fromString(conversation_id), objectMapper.writeValueAsString(botMsgNode));

                            messageService.sendMessage(
                                            UUID.fromString("2d61b0d1-1512-494b-ba1d-bf1c55de1173"),
                                            UUID.fromString(conversation_id),
                                            aiResponse,
                                            null
                                            );

                        } catch (Exception e) {
                            System.err.println("Lỗi khi gọi Charles AI: " + e.getMessage());
                        }
                    });
                }
            }
        }

        @OnClose
        public void onClose(WebSocketConnection connection, @PathParam("conversation_id") String conversation_id){

            String user_id = connectionUserMap.getOrDefault(connection.id(), jwt.getSubject());

            System.out.println("User ["+user_id+"] left the group chat ["+conversation_id+"]!");

            if (user_id != null) {

                userService.updateUserStatus(UUID.fromString(user_id), false);
            }

            // Dọn rác
            connectionUserMap.remove(connection.id());
        }

        private void broadcastToRoom(UUID conversation_id, String json_msg){
            connections.forEach(conn -> {
                try {
                    if(conversation_id.toString().equals(conn.pathParam("conversation_id"))){
                        conn.sendTextAndAwait(json_msg);
                    }
                } catch (Exception e) {
                    System.err.println("Bỏ qua kết nối lỗi: " + e.getMessage());
                }
            });
        }
    }