package com.meta.junior.service;

import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.post.PostResponseDTO;

import java.util.UUID;

public interface PostSearchService {

    /**
     * Tìm kiếm bài viết theo từ khóa có phân trang và kiểm tra quyền riêng tư
     * @param currentUserId ID người dùng thực hiện tìm kiếm
     * @param keyword Từ khóa tìm kiếm
     * @param page Số trang (bắt đầu từ 0)
     * @param size Số phần tử mỗi trang
     */
    PageResponseDTO<PostResponseDTO> searchByKeyword(UUID currentUserId, String keyword, int page, int size);

    /**
     * Tìm kiếm bài viết theo Hashtag có phân trang và kiểm tra quyền riêng tư
     * @param currentUserId ID người dùng thực hiện tìm kiếm
     * @param tagName Tên hashtag (có hoặc không có tiền tố #)
     * @param page Số trang (bắt đầu từ 0)
     * @param size Số phần tử mỗi trang
     */
    PageResponseDTO<PostResponseDTO> searchByHashtag(UUID currentUserId, String tagName, int page, int size);
}
