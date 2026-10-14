
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

        // Đã chọn đúng emoji này: nhấn lại để gỡ
        if (existing != null
                && existing.emojiType.equals(request.emojiType)) {
            EmojiResponse response = toResponse(existing);
            response.active = false;
            emojiRepository.delete(existing);
            return response;
        }

        // Đã có emoji khác: đổi sang emoji mới
        if (existing != null) {
            existing.emojiType = request.emojiType;
            return toResponse(existing);
        }

        // Chưa có emoji: tạo mới
        Emoji emoji = new Emoji();
        emoji.id = UUID.randomUUID();
        emoji.emojiType = request.emojiType;
        emoji.postId = request.postId;
        emoji.cmtId = request.cmtId;
        emoji.authorId = request.authorId;
        emoji.createdAt = LocalDateTime.now();

        emojiRepository.persist(emoji);
        return toResponse(emoji);
    }

    public List<EmojiResponse> getByPostId(UUID postId) {
        if (postId == null) {
            throw new BadRequestException("postId khong hop le");
        }

        return emojiRepository.findByPostId(postId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<EmojiResponse> getByCommentId(UUID cmtId) {
        if (cmtId == null) {
            throw new BadRequestException("cmtId khong hop le");
        }

        return emojiRepository.findByCommentId(cmtId).stream()
                .map(this::toResponse)
                .toList();
    }

    public EmojiResponse getById(UUID id) {
        return toResponse(findEmoji(id));
    }

    @Transactional
    public EmojiResponse update(UUID id, EmojiRequest request) {
        if (request == null
                || request.emojiType == null
                || request.emojiType.isBlank()) {
            throw new BadRequestException(
                    "emojiType khong duoc de trong");
        }

        Emoji emoji = findEmoji(id);
        emoji.emojiType = request.emojiType;
        return toResponse(emoji);
    }

    @Transactional
    public void delete(UUID id) {
        Emoji emoji = findEmoji(id);
        emojiRepository.delete(emoji);
    }

    private void validateRequest(EmojiRequest request) {
        if (request == null) {
            throw new BadRequestException("Du lieu emoji khong hop le");
        }

        if (request.emojiType == null || request.emojiType.isBlank()) {
            throw new BadRequestException(
                    "emojiType khong duoc de trong");
        }

        if (request.authorId == null) {
            throw new BadRequestException(
                    "authorId khong duoc de trong");
        }

        boolean hasPost = request.postId != null;
        boolean hasComment = request.cmtId != null;

        if (hasPost == hasComment) {
            throw new BadRequestException(
                    "Emoji phai thuoc mot bai viet hoac mot binh luan");
        }
    }

    private Emoji findEmoji(UUID id) {
        if (id == null) {
            throw new BadRequestException("id khong hop le");
        }

        Emoji emoji = emojiRepository.findById(id);
        if (emoji == null) {
            throw new NotFoundException("Khong tim thay emoji");
        }

        return emoji;
    }

    private EmojiResponse toResponse(Emoji emoji) {
        EmojiResponse response = new EmojiResponse();
        response.id = emoji.id;
        response.emojiType = emoji.emojiType;
        response.postId = emoji.postId;
        response.cmtId = emoji.cmtId;
        response.authorId = emoji.authorId;
        response.createdAt = emoji.createdAt;
        response.active = true;
        return response;
    }
}
