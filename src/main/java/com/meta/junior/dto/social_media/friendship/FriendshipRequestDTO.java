package com.meta.junior.dto.social_media.friendship;

import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class FriendshipRequestDTO {
    private UUID receiverId;
}