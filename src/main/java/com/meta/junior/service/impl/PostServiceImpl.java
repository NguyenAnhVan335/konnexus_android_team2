package com.meta.junior.service.impl;

import com.meta.junior.common.PostMediaType;
import com.meta.junior.common.PostPrivacy;
import com.meta.junior.common.SystemRole;
import com.meta.junior.dto.PageResponseDTO;
import com.meta.junior.dto.social_media.post.CreatePostRequestDTO;
import com.meta.junior.dto.social_media.post.PostMediaDTO;
import com.meta.junior.dto.social_media.post.PostResponseDTO;
import com.meta.junior.dto.social_media.post.UpdatePostRequestDTO;
import com.meta.junior.entity.Post;
import com.meta.junior.entity.PostMedia;
import com.meta.junior.entity.User;
import com.meta.junior.repository.PostRepo;
import com.meta.junior.repository.UserRepo;
import com.meta.junior.service.HashtagService;
import com.meta.junior.service.PostService;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotFoundException;

import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class PostServiceImpl implements PostService {

    @Inject
    PostRepo postRepo;

    @Inject
    UserRepo userRepo;

    @Inject
    HashtagService hashtagService;

    @Override
    @Transactional
    public PostResponseDTO createPost(UUID currentUserId, CreatePostRequestDTO dto) {
        User author = userRepo.findByIdOptional(currentUserId)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy thông tin người dùng"));

        Post post = Post.builder()
                .author(author)
                .content(dto.getContent().trim())
                .privacy(dto.getPrivacy() != null ? dto.getPrivacy() : PostPrivacy.PUBLIC)
                .like_count(0)
                .comment_count(0)
                .is_edited(false)
                .isDeleted(false)
                .build();

        // Xử lý danh sách media nếu có
        if (dto.getMedia_list() != null && !dto.getMedia_list().isEmpty()) {
            for (int i = 0; i < dto.getMedia_list().size(); i++) {
                PostMediaDTO mediaDTO = dto.getMedia_list().get(i);
                PostMedia media = PostMedia.builder()
                        .media_url(mediaDTO.getMedia_url().trim())
                        .media_type(mediaDTO.getMedia_type() != null ? mediaDTO.getMedia_type() : PostMediaType.IMAGE)
                        .display_order(mediaDTO.getDisplay_order() > 0 ? mediaDTO.getDisplay_order() : i)
                        .build();
                post.addMedia(media);
            }
        }

        postRepo.persist(post);

        // Tự động trích xuất và đồng bộ hashtags
        hashtagService.syncPostHashtags(post, post.getContent());
        List<String> tags = hashtagService.getHashtagNamesByPostId(post.getId());

        return PostResponseDTO.fromEntity(post, tags);
    }

    @Override
    public PostResponseDTO getPostDetail(UUID currentUserId, UUID postId) {
        Post post = postRepo.findActiveByIdWithDetails(postId)
                .orElseThrow(() -> new NotFoundException("Bài viết không tồn tại hoặc đã bị xóa"));

        // Kiểm tra quyền xem bài viết riêng tư
        if (post.getPrivacy() == PostPrivacy.PRIVATE && !post.getAuthor().getId().equals(currentUserId)) {
            throw new ForbiddenException("Bạn không có quyền xem bài viết riêng tư này");
        }

        List<String> tags = hashtagService.getHashtagNamesByPostId(post.getId());
        return PostResponseDTO.fromEntity(post, tags);
    }

    @Override
    public PageResponseDTO<PostResponseDTO> getNewsfeed(UUID currentUserId, int page, int size) {
        int pageIndex = Math.max(0, page);
        int pageSize = Math.min(Math.max(1, size), 50);

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<Post> query = postRepo.findFeed(currentUserId, pageable);

        List<PostResponseDTO> items = query.list().stream()
                .map(p -> PostResponseDTO.fromEntity(p, hashtagService.getHashtagNamesByPostId(p.getId())))
                .toList();

        return PageResponseDTO.of(items, query.page().index, query.page().size, query.count(), query.pageCount());
    }

    @Override
    public PageResponseDTO<PostResponseDTO> getUserTimeline(UUID currentUserId, UUID targetUserId, int page, int size) {
        // Kiểm tra người dùng có tồn tại không
        if (userRepo.findByIdOptional(targetUserId).isEmpty()) {
            throw new NotFoundException("Không tìm thấy người dùng này");
        }

        int pageIndex = Math.max(0, page);
        int pageSize = Math.min(Math.max(1, size), 50);

        Page pageable = Page.of(pageIndex, pageSize);
        PanacheQuery<Post> query = postRepo.findUserTimeline(currentUserId, targetUserId, pageable);

        List<PostResponseDTO> items = query.list().stream()
                .map(p -> PostResponseDTO.fromEntity(p, hashtagService.getHashtagNamesByPostId(p.getId())))
                .toList();

        return PageResponseDTO.of(items, query.page().index, query.page().size, query.count(), query.pageCount());
    }

    @Override
    @Transactional
    public PostResponseDTO updatePost(UUID currentUserId, UUID postId, UpdatePostRequestDTO dto) {
        Post post = postRepo.findActiveByIdWithDetails(postId)
                .orElseThrow(() -> new NotFoundException("Bài viết không tồn tại hoặc đã bị xóa"));

        // Strict Ownership Check: Chỉ chính tác giả mới được sửa
        if (!post.getAuthor().getId().equals(currentUserId)) {
            throw new ForbiddenException("Bạn không có quyền chỉnh sửa bài viết của người khác");
        }

        post.setContent(dto.getContent().trim());
        if (dto.getPrivacy() != null) {
            post.setPrivacy(dto.getPrivacy());
        }
        post.set_edited(true);

        // Cập nhật lại hashtags khi nội dung bài viết thay đổi
        hashtagService.syncPostHashtags(post, post.getContent());
        List<String> tags = hashtagService.getHashtagNamesByPostId(post.getId());

        return PostResponseDTO.fromEntity(post, tags);
    }

    @Override
    @Transactional
    public void deletePost(UUID currentUserId, UUID postId) {
        Post post = postRepo.findActiveById(postId)
                .orElseThrow(() -> new NotFoundException("Bài viết không tồn tại hoặc đã bị xóa"));

        User currentUser = userRepo.findByIdOptional(currentUserId)
                .orElseThrow(() -> new NotFoundException("Không tìm thấy thông tin người dùng thực hiện thao tác"));

        boolean isAuthor = post.getAuthor().getId().equals(currentUserId);
        boolean isAdmin = currentUser.getRole() == SystemRole.ADMIN;

        // Chỉ tác giả hoặc ADMIN mới được xóa
        if (!isAuthor && !isAdmin) {
            throw new ForbiddenException("Bạn không có quyền xóa bài viết này");
        }

        // Xóa mềm: Bật cờ is_deleted = true
        post.set_deleted(true);

        // Giảm usage_count và gỡ liên kết hashtag
        hashtagService.removePostHashtags(post.getId());
    }
}
