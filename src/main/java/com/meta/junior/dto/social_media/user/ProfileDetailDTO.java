package com.meta.junior.dto.social_media.user;

import com.meta.junior.common.FriendRequestStatus;
import lombok.Data;

import java.time.LocalDate;

@Data
public class ProfileDetailDTO {
    public String username;
    public String avatarUrl;
    public LocalDate birthday;
    public String note;
    public FriendRequestStatus requestStatus;
}
