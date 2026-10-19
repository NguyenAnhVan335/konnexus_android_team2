package com.meta.junior.service.impl;

import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.CommentResponseDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.CreateCommentRequestDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.ReactionRequestDTO;
import com.meta.junior.dto.social_media.hashtag.interaction.ReactionUserResponseDTO;
import com.meta.junior.entity.Post;
import com.meta.junior.entity.PostComment;
import com.meta.junior.entity.PostReaction;
import com.meta.junior.entity.User;
import com.meta.junior.repository.PostCommentRepo;
import com.meta.junior.repository.PostReactionRepo;
import com.meta.junior.repository.PostRepo;
import com.meta.junior.repository.UserRepo;
import com.meta.junior.service.PostInteractionService;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotFoundException;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class PostInteractionServiceImpl implements PostInteractionService {

    @Inject
    PostRepo postRepo;

    @Inject
    UserRepo userRepo;

    @Inject
    PostReactionRepo reactionRepo;

    @Inject
    PostCommentRepo commentRepo;

    @Override
    @Transactional
    public void toggleReaction(UUID currentUserId, UUID postId, ReactionRequestDTO dto) {
        Post post = postRepo.findActiveById(postId)
                .orElseThrow(() -> new NotFoundException("Bài viết không tồn tại hoặc đã bị xóa"));

        User user = userRepo.findByIdOptional(currentUserId)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy người dùng"));

        Optional<PostReaction> existingReaction = reactionRepo.findByPostAndUser(postId, currentUserId);

        if (existingReaction.isPresent()) {
            PostReaction reaction = existingReaction.get();
            if (reaction.getType() == dto.getType()) {
                reactionRepo.delete(reaction);
                post.setLike_count(Math.max(0, post.getLike_count() - 1));
            } else {
                reaction.setType(dto.getType());
            }
        } else {
            PostReaction newReaction = PostReaction.builder()
                    .post(post)
                    .author(user)
                    .type(dto.getType())
                    .build();
            reactionRepo.persist(newReaction);
            post.setLike_count(post.getLike_count() + 1);
        }
    }

    @Override
    @Transactional
    public CommentResponseDTO createComment(UUID currentUserId, UUID postId, CreateCommentRequestDTO dto) {
        Post post = postRepo.findActiveById(postId)
                .orElseThrow(() -> new NotFoundException("Bài viết không tồn tại hoặc đã bị xóa"));

        User user = userRepo.findByIdOptional(currentUserId)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy người dùng"));

        PostComment parentComment = null;
        if (dto.getParentId() != null) {
            parentComment = commentRepo.findActiveById(dto.getParentId())
                    .orElseThrow(() -> new NotFoundException("Bình luận cấp cha không tồn tại"));
        }

        PostComment comment = PostComment.builder()
                .post(post)
                .author(user)
                .content(dto.getContent().trim())
                .parentComment(parentComment)
                .build();

        commentRepo.persist(comment);
        post.setComment_count(post.getComment_count() + 1);

        return CommentResponseDTO.fromEntity(comment);
    }

    @Override
    public PageResponseDTO<CommentResponseDTO> getPostComments(UUID postId, int page, int size) {
        int pageIndex = Math.max(0, page);
        int pageSize = Math.min(Math.max(1, size), 50);

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<PostComment> query = commentRepo.findByPostId(postId, pageable);

        List<CommentResponseDTO> items = query.list().stream()
                .map(CommentResponseDTO::fromEntity)
                .toList();

        return PageResponseDTO.of(items, query.page().index, query.page().size, query.count(), query.pageCount());
    }

    @Override
    @Transactional
    public void deleteComment(UUID currentUserId, UUID commentId) {
        PostComment comment = commentRepo.findActiveById(commentId)
                .orElseThrow(() -> new NotFoundException("Bình luận không tồn tại hoặc đã bị xóa"));

        boolean isAuthor = comment.getAuthor().getId().equals(currentUserId);
        boolean isPostOwner = comment.getPost().getAuthor().getId().equals(currentUserId);

        if (!isAuthor && !isPostOwner) {
            throw new ForbiddenException("Bạn không có quyền xóa bình luận này");
        }

        comment.setContent("Bình luận đã bị xóa.");
    }

    @Override
    public PageResponseDTO<ReactionUserResponseDTO> getPostReactions(UUID postId, int page, int size) {
        /** 1. Kiểm tra bài viết có tồn tại hay không */
        postRepo.findActiveById(postId)
                .orElseThrow(() -> new NotFoundException("Bài viết không tồn tại hoặc đã bị xóa"));

        /** 2. Phân trang */
        int pageIndex = Math.max(0, page);
        int pageSize = Math.min(Math.max(1, size), 50);

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<PostReaction> query = reactionRepo.findByPostId(postId, pageable);

        /** 3. Chuyển đổi Entity sang DTO */
        List<ReactionUserResponseDTO> items = query.list().stream()
                .map(ReactionUserResponseDTO::fromEntity)
                .toList();

        return PageResponseDTO.of(items, query.page().index, query.page().size, query.count(), query.pageCount());
    }
}