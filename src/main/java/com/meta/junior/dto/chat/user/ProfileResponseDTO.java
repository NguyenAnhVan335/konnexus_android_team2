package alan.nguyen.dto.chatify.user;

public class ProfileResponseDTO {
    public String username;
    public String email;
    public String avatar_url;
    public String password;

    public ProfileResponseDTO(String email, String avatar_url, String username, String password) {
        this.email = email;
        this.avatar_url = avatar_url;
        this.username = username;
        this.password = password;
    }
}
