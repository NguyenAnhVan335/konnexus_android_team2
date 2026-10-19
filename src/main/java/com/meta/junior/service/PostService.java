package com.meta.junior.service;

import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.post.CreatePostRequestDTO;
import com.meta.junior.dto.social_media.post.PostResponseDTO;
import com.meta.junior.dto.social_media.post.UpdatePostRequestDTO;

import java.util.UUID;

public interface PostService {

    /**
     * Tạo bài viết mới kèm tệp đa phương tiện
     */
    PostResponseDTO createPost(UUID currentUserId, CreatePostRequestDTO dto);

    /**
     * Xem chi tiết một bài viết
     */
    PostResponseDTO getPostDetail(UUID currentUserId, UUID postId);

    /**
     * Lấy bảng tin (Newsfeed) có phân trang
     */
    PageResponseDTO<PostResponseDTO> getNewsfeed(UUID currentUserId, int page, int size);

    /**
     * Lấy danh sách bài viết trên trang cá nhân (Timeline) có phân trang
     */
    PageResponseDTO<PostResponseDTO> getUserTimeline(UUID currentUserId, UUID targetUserId, int page, int size);

    /**
     * Cập nhật nội dung hoặc quyền riêng tư của bài viết (Chỉ tác giả)
     */
    PostResponseDTO updatePost(UUID currentUserId, UUID postId, UpdatePostRequestDTO dto);

    /**
     * Xóa mềm bài viết (Chỉ tác giả hoặc ADMIN)
     */
    void deletePost(UUID currentUserId, UUID postId);
}
