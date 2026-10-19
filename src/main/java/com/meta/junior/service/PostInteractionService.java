package com.meta.junior.service;

import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.CommentResponseDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.CreateCommentRequestDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.ReactionRequestDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.ReactionUserResponseDTO;

import java.util.UUID;

public interface PostInteractionService {

    /** Thả, thay đổi hoặc gỡ cảm xúc bài viết */
    void toggleReaction(UUID currentUserId, UUID postId, ReactionRequestDTO dto);

    /** Tạo mới một bình luận */
    CommentResponseDTO createComment(UUID currentUserId, UUID postId, CreateCommentRequestDTO dto);

    /** Lấy danh sách bình luận có phân trang */
    PageResponseDTO<CommentResponseDTO> getPostComments(UUID postId, int page, int size);

    /** Lấy danh sách reaction có phân trang */
    PageResponseDTO<ReactionUserResponseDTO> getPostReactions(UUID postId, int page, int size);

    /** Xóa mềm bình luận (Tác giả bình luận hoặc tác giả bài viết có quyền xóa) */
    void deleteComment(UUID currentUserId, UUID commentId);
}