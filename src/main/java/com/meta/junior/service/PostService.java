package com.meta.junior.service;

import com.meta.junior.dto.MediaRequest;
import com.meta.junior.dto.PageData;
import com.meta.junior.dto.post.PostCreateRequest;
import com.meta.junior.dto.post.PostResponse;
import com.meta.junior.dto.post.PostUpdateRequest;
import com.meta.junior.entity.Post;
import com.meta.junior.entity.PostMedia;
import com.meta.junior.repository.PostRepository;
import com.meta.junior.security.CurrentUserProvider;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotFoundException;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class PostService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_MEDIA = 10;

    @Inject
    PostRepository postRepository;

    @Inject
    CurrentUserProvider currentUserProvider;

    @Inject
    EntityManager entityManager;

    @Transactional
    public PostResponse createPost(PostCreateRequest request) {
        UUID authorId = currentUserProvider.getCurrentUserId();
        // TODO: verify the user exists and is active once a User entity / auth is available.
        validateContentAndMedia(request.content(), request.mediaList());

        Post post = new Post();
        post.setAuthorId(authorId);
        post.setContent(normalize(request.content()));
        post.setPrivacy(request.privacy());
        post.setStatus(Boolean.TRUE);
        applyMedia(post, request.mediaList());
        postRepository.persist(post);
        // Flush so generated ids (post + media) are available for the response payload.
        entityManager.flush();
        return PostResponse.from(post);
    }

    @Transactional
    public PageData<PostResponse> getPosts(int page, int size) {
        Page p = validatePage(page, size);
        PanacheQuery<Post> query = postRepository.findActive();
        long total = query.count();
        List<PostResponse> content = query.page(p).list().stream()
                .map(PostResponse::from)
                .toList();
        return PageData.of(content, page, size, total);
    }

    @Transactional
    public PostResponse getPostById(UUID id) {
        Post post = postRepository.findActiveById(id)
                .orElseThrow(() -> new NotFoundException("Post not found: " + id));
        return PostResponse.from(post);
    }

    @Transactional
    public PostResponse updatePost(UUID id, PostUpdateRequest request) {
        Post post = postRepository.findActiveById(id)
                .orElseThrow(() -> new NotFoundException("Post not found: " + id));

        UUID currentUserId = currentUserProvider.getCurrentUserId();
        if (!post.getAuthorId().equals(currentUserId)) {
            throw new ForbiddenException("You are not allowed to update this post");
        }

        validateContentAndMedia(request.content(), request.mediaList());
        post.setContent(normalize(request.content()));
        post.setPrivacy(request.privacy());
        if (request.mediaList() != null) {
            post.clearMedia();
            applyMedia(post, request.mediaList());
        }
        post.setEdited(true);
        // id, authorId, likeCount, commentCount, createdAt and status are intentionally left unchanged.
        // Flush so new media ids are generated and orphaned media is removed before building the response.
        entityManager.flush();
        return PostResponse.from(post);
    }

    @Transactional
    public void deletePost(UUID id) {
        Post post = postRepository.findActiveById(id)
                .orElseThrow(() -> new NotFoundException("Post not found: " + id));

        UUID currentUserId = currentUserProvider.getCurrentUserId();
        if (!post.getAuthorId().equals(currentUserId)) {
            throw new ForbiddenException("You are not allowed to delete this post");
        }

        // Soft delete: keep the record, flip the flag.
        post.setStatus(Boolean.FALSE);
    }

    @Transactional
    public PageData<PostResponse> getPostsByUser(UUID userId, int page, int size) {
        // TODO: verify the user exists once a User entity is available.
        Page p = validatePage(page, size);
        PanacheQuery<Post> query = postRepository.findActiveByAuthor(userId);
        long total = query.count();
        List<PostResponse> content = query.page(p).list().stream()
                .map(PostResponse::from)
                .toList();
        return PageData.of(content, page, size, total);
    }

    private static void applyMedia(Post post, List<MediaRequest> mediaRequests) {
        if (mediaRequests == null) {
            return;
        }
        for (MediaRequest mediaRequest : mediaRequests) {
            PostMedia media = new PostMedia();
            media.setMediaUrl(normalize(mediaRequest.mediaUrl()));
            media.setMediaType(mediaRequest.mediaType());
            media.setDisplayOrder(mediaRequest.displayOrder() != null ? mediaRequest.displayOrder() : 0);
            post.addMedia(media);
        }
    }

    private static void validateContentAndMedia(String content, List<MediaRequest> mediaList) {
        boolean hasContent = content != null && !content.isBlank();
        boolean hasMedia = mediaList != null && !mediaList.isEmpty();
        if (!hasContent && !hasMedia) {
            throw new BadRequestException("At least one of content or media_list is required");
        }
        if (mediaList != null) {
            if (mediaList.size() > MAX_MEDIA) {
                throw new BadRequestException("media_list must contain at most " + MAX_MEDIA + " items");
            }
            for (MediaRequest media : mediaList) {
                if (media == null || media.mediaUrl() == null || media.mediaUrl().isBlank()) {
                    throw new BadRequestException("Each media item requires a media_url");
                }
                validateMediaUrl(media.mediaUrl());
            }
        }
    }

    private static void validateMediaUrl(String mediaUrl) {
        try {
            URI uri = new URI(mediaUrl.trim());
            String scheme = uri.getScheme();
            if (scheme == null
                    || (!scheme.equalsIgnoreCase("http") && !scheme.equalsIgnoreCase("https"))
                    || uri.getHost() == null) {
                throw new BadRequestException("media_url must be a valid http/https URL");
            }
        } catch (URISyntaxException e) {
            throw new BadRequestException("media_url must be a valid http/https URL");
        }
    }

    private static String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static Page validatePage(int page, int size) {
        if (page < 0) {
            throw new BadRequestException("page must be >= 0");
        }
        if (size < 1 || size > MAX_PAGE_SIZE) {
            throw new BadRequestException("size must be between 1 and " + MAX_PAGE_SIZE);
        }
        return Page.of(page, size);
    }
}
