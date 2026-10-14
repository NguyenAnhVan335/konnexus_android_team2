
package com.meta.junior.service;

import com.meta.junior.entity.PostComment;
import com.meta.junior.repository.PostCommentRepository;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.NotFoundException;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class PostCommentService {

    @Inject
    PostCommentRepository commentRepository;

    // Tạo bình luận
    @Transactional
    public PostComment create(PostComment comment) {
        if (comment == null) {
            throw new BadRequestException("Du lieu binh luan khong hop le");
        }

        if (comment.postId == null) {
            throw new BadRequestException("postId khong duoc de trong");
        }

        if (comment.content == null || comment.content.isBlank()) {
            throw new BadRequestException("Noi dung binh luan khong duoc de trong");
        }

        comment.id = UUID.randomUUID();
        comment.createdAt = java.time.LocalDateTime.now();
        comment.status = true;

        commentRepository.persist(comment);
        return comment;
    }

    // Lấy danh sách bình luận của bài viết
    public List<PostComment> getByPostId(UUID postId) {
        if (postId == null) {
            throw new BadRequestException("postId khong hop le");
        }

        return commentRepository.findByPostId(postId);
    }

    // Lấy một bình luận theo ID
    public PostComment getById(UUID id) {
        PostComment comment = commentRepository.findById(id);

        if (comment == null) {
            throw new NotFoundException("Khong tim thay binh luan");
        }

        return comment;
    }

    // Cập nhật bình luận
    @Transactional
    public PostComment update(UUID id, PostComment request) {
        PostComment comment = getById(id);

        if (request == null) {
            throw new BadRequestException("Du lieu cap nhat khong hop le");
        }

        if (request.content == null || request.content.isBlank()) {
            throw new BadRequestException("Noi dung binh luan khong duoc de trong");
        }

        comment.content = request.content;
        comment.image = request.image;

        return comment;
    }

    // Xóa mềm: chuyển status thành false
    @Transactional
    public void delete(UUID id) {
        PostComment comment = getById(id);
        comment.status = false;
    }
}
