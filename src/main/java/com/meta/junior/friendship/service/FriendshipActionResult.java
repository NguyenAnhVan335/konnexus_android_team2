package com.meta.junior.friendship.service;

import com.meta.junior.friendship.dto.FriendshipDto;

public record FriendshipActionResult(String message, FriendshipDto friendship) {
}
