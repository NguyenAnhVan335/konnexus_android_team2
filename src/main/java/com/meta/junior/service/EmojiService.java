
package com.meta.junior.service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import com.meta.junior.dto.EmojiRequest;
import com.meta.junior.dto.EmojiResponse;
import com.meta.junior.entity.Emoji;
import com.meta.junior.repository.EmojiRepository;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;

@ApplicationScoped
public class EmojiService {

    @Inject
    EmojiRepository emojiRepository;

    // Thêm, đổi hoặc gỡ emoji
    @Transactional
    public EmojiResponse toggle(EmojiRequest request) {
        validateRequest(request);

        Emoji existing;

        if (request.postId != null) {
            existing = emojiRepository.findByPostAndAuthor(
                    request.postId, request.authorId);
        } else {
            existing = emojiRepository.findByCommentAndAuthor(
                    request.cmtId, request.authorId);
        }

        // Nếu chọn lại cùng emoji thì gỡ
        if (existing != null
                && existing.emojiType.equals(request.emojiType)) {

            EmojiResponse response = toResponse(existing);
            response.active = false;

            emojiRepository.delete(existing);
            return response;
        }

        // Nếu đã có emoji khác thì đổi loại emoji
        if (existing != null) {
            existing.emojiType = request.emojiType;
            existing.authorName = request.authorName;
            existing.authorAvatar = request.authorAvatar;
            return toResponse(existing);
        }

        // Nếu chưa có thì tạo mới
        Emoji emoji = new Emoji();
        emoji.id = UUID.randomUUID();
        emoji.emojiType = request.emojiType;
        emoji.postId = request.postId;
        emoji.cmtId = request.cmtId;
        emoji.authorId = request.authorId;
        emoji.createdAt = LocalDateTime.now();
        emoji.authorName = request.authorName;
        emoji.authorAvatar = request.authorAvatar;

        emojiRepository.persist(emoji);

        return toResponse(emoji);
    }

    // Lấy emoji theo bài viết
    public List<EmojiResponse> getByPostId(UUID postId) {
        if (postId == null) {
            throw new BadRequestException("postId không hợp lệ");
        }

        return emojiRepository.findByPostId(postId)
            .stream()
            .map(this::toResponse)
            .toList();
    }


    // Lấy emoji theo bình luận
    public List<EmojiResponse> getByCommentId(UUID cmtId) {
        if (cmtId == null) {
            throw new BadRequestException(
                    "cmtId không hợp lệ");
        }

        return emojiRepository.findByCommentId(cmtId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // Lấy emoji theo ID
    public EmojiResponse getById(UUID id) {
        return toResponse(findEmoji(id));
    }

    // Cập nhật loại emoji theo ID
    @Transactional
    public EmojiResponse update(
            UUID id,
            EmojiRequest request) {

        if (request == null
                || request.emojiType == null
                || request.emojiType.isBlank()) {
            throw new BadRequestException(
                    "emojiType không được để trống");
        }

        Emoji emoji = findEmoji(id);
        emoji.emojiType = request.emojiType;

        return toResponse(emoji);
    }

    // Xóa emoji theo ID
    @Transactional
    public void delete(UUID id) {
        Emoji emoji = findEmoji(id);
        emojiRepository.delete(emoji);
    }

    // Kiểm tra dữ liệu đầu vào
    private void validateRequest(EmojiRequest request) {
        if (request == null) {
            throw new BadRequestException(
                    "Dữ liệu emoji không hợp lệ");
        }

        if (request.emojiType == null
                || request.emojiType.isBlank()) {
            throw new BadRequestException(
                    "emojiType không được để trống");
        }

        if (request.authorId == null) {
            throw new BadRequestException(
                    "authorId không được để trống");
        }

        boolean hasPost = request.postId != null;
        boolean hasComment = request.cmtId != null;

        if (hasPost == hasComment) {
            throw new BadRequestException(
                    "Emoji phải thuộc một bài viết "
                    + "hoặc một bình luận");
        }
    }

    // Tìm emoji theo ID
    private Emoji findEmoji(UUID id) {
        if (id == null) {
            throw new BadRequestException(
                    "id không hợp lệ");
        }

        Emoji emoji = emojiRepository.findById(id);

        if (emoji == null) {
            throw new NotFoundException(
                    "Không tìm thấy emoji");
        }

        return emoji;
    }

    // Chuyển Entity thành Response DTO
    
    private EmojiResponse toResponse(Emoji emoji) {
        EmojiResponse response = new EmojiResponse();

        response.id = emoji.id;
        response.emojiType = emoji.emojiType;
        response.postId = emoji.postId;
        response.cmtId = emoji.cmtId;
        response.authorId = emoji.authorId;

        // Bổ sung tên và avatar
        response.authorName = emoji.authorName;
        response.authorAvatar = emoji.authorAvatar;

        response.createdAt = emoji.createdAt;
        response.active = true;

        return response;
    }

}
