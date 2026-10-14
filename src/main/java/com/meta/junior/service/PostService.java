package com.meta.junior.service;

import com.meta.junior.dto.AuthorResponse;
import com.meta.junior.dto.MediaRequest;
import com.meta.junior.dto.PageData;
import com.meta.junior.dto.post.CommentResponse;
import com.meta.junior.dto.post.PostCreateRequest;
import com.meta.junior.dto.post.PostDetailResponse;
import com.meta.junior.dto.post.PostResponse;
import com.meta.junior.dto.post.PostUpdateRequest;
import com.meta.junior.dto.post.ReactionSummaryResponse;
import com.meta.junior.entity.Post;
import com.meta.junior.entity.PostComment;
import com.meta.junior.entity.PostMedia;
import com.meta.junior.entity.User;
import com.meta.junior.friendship.entity.FriendshipEntity;
import com.meta.junior.friendship.repository.FriendshipRepository;
import com.meta.junior.repository.PostRepository;
import com.meta.junior.repository.UserRepo;
import com.meta.junior.security.CurrentUserProvider;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import io.quarkus.panache.common.Sort;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.BadRequestException;
import jakarta.ws.rs.ForbiddenException;
import jakarta.ws.rs.NotFoundException;

import java.net.URI;
import java.net.URISyntaxException;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Business logic of the Post API.
 *
 * <p>Privacy is enforced here and in {@link PostRepository}: a viewer only ever receives
 * {@code PUBLIC} posts, their own posts (any privacy) and the {@code FRIENDS} posts of their accepted
 * friends. Anonymous viewers only receive {@code PUBLIC} posts.</p>
 */
@ApplicationScoped
public class PostService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_MEDIA = 10;
    private static final int MAX_TRENDING_DAYS = 365;

    @Inject
    PostRepository postRepository;

    @Inject
    CurrentUserProvider currentUserProvider;

    @Inject
    FriendshipRepository friendshipRepository;

    @Inject
    PostInteractionService postInteractionService;

    @Inject
    UserRepo userRepo;

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
        return toResponse(post, authorId);
    }

    /**
     * Returns the feed visible to the caller: {@code PUBLIC} posts, the caller's own posts and the
     * {@code FRIENDS} posts of their accepted friends. An anonymous caller only gets {@code PUBLIC}
     * posts. Soft-deleted posts are never returned.
     */
    @Transactional
    public PageData<PostResponse> getPosts(int page, int size) {
        Page p = validatePage(page, size);
        Viewer viewer = resolveViewer();
        PanacheQuery<Post> query = postRepository.findVisibleTo(
                viewer.userId(), viewer.friendIds(), Sort.descending("createdAt"));
        long total = query.count();
        List<PostResponse> content = toResponses(query.page(p).list(), viewer.userId());
        return PageData.of(content, page, size, total);
    }

    /**
     * Returns the full representation of a post (post data + reactions + comments), but only when the
     * post is visible to the caller. A {@code PRIVATE} post of somebody else — or a {@code FRIENDS}
     * post of a non-friend — is indistinguishable from a non-existing one (404).
     */
    @Transactional
    public PostDetailResponse getPostById(UUID id) {
        Viewer viewer = resolveViewer();
        Post post = postRepository.findVisibleById(id, viewer.userId(), viewer.friendIds())
                .orElseThrow(() -> new NotFoundException("Post not found: " + id));
        return toDetail(post, viewer.userId());
    }

    /**
     * Returns the trending feed: the visible posts ranked by the interactions they received during the
     * last {@code days} days (reactions + comments), newest first on a tie.
     *
     * <p>Only posts visible to the caller can ever be returned — the privacy filter is applied in SQL
     * before the ranking, so a trending page can never expose a post the caller may not see.</p>
     */
    @Transactional
    public PageData<PostResponse> getTrendingPosts(int page, int size, int days) {
        Page p = validatePage(page, size);
        if (days < 1 || days > MAX_TRENDING_DAYS) {
            throw new BadRequestException("days must be between 1 and " + MAX_TRENDING_DAYS);
        }
        Viewer viewer = resolveViewer();
        LocalDateTime windowStart = LocalDateTime.now().minusDays(days);

        List<Object[]> visiblePosts = postRepository.findVisibleIdAndCreatedAt(viewer.userId(), viewer.friendIds());
        List<UUID> visibleIds = visiblePosts.stream()
                .map(row -> (UUID) row[0])
                .toList();
        Map<UUID, Integer> reactions = postInteractionService.countReactionsByPost(visibleIds, windowStart);
        Map<UUID, Integer> comments = postInteractionService.countCommentsByPost(visibleIds, windowStart);

        List<TrendingCandidate> ranked = visiblePosts.stream()
                .map(row -> {
                    UUID postId = (UUID) row[0];
                    int score = reactions.getOrDefault(postId, 0) + comments.getOrDefault(postId, 0);
                    return new TrendingCandidate(postId, (LocalDateTime) row[1], score);
                })
                .sorted(Comparator.comparingInt(TrendingCandidate::score).reversed()
                        .thenComparing(TrendingCandidate::createdAt, Comparator.reverseOrder()))
                .toList();

        List<UUID> pageIds = ranked.stream()
                .skip((long) p.index * p.size)
                .limit(p.size)
                .map(TrendingCandidate::postId)
                .toList();
        if (pageIds.isEmpty()) {
            return PageData.of(List.of(), page, size, ranked.size());
        }

        Map<UUID, Post> postsById = postRepository.list("id in ?1", pageIds).stream()
                .collect(Collectors.toMap(Post::getId, post -> post));
        List<Post> ordered = pageIds.stream()
                .map(postsById::get)
                .filter(Objects::nonNull)
                .toList();
        return PageData.of(toResponses(ordered, viewer.userId()), page, size, ranked.size());
    }

    /**
     * Updates the mutable fields of a post. Only the author may update it, and {@code privacy} is
     * required (it is validated here rather than with bean validation so that the delete payload
     * described by {@link PostUpdateRequest} stays minimal).
     */
    @Transactional
    public PostResponse updatePost(UUID id, PostUpdateRequest request) {
        Post post = postRepository.findActiveById(id)
                .orElseThrow(() -> new NotFoundException("Post not found: " + id));

        UUID currentUserId = currentUserProvider.getCurrentUserId();
        if (!post.getAuthorId().equals(currentUserId)) {
            throw new ForbiddenException("You are not allowed to update this post");
        }
        if (request.privacy() == null) {
            throw new BadRequestException("privacy is required");
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
        return toResponse(post, currentUserId);
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

    /**
     * Returns the posts of a user that the caller may see: {@code PUBLIC} ones for everybody, plus the
     * {@code FRIENDS} ones for accepted friends, plus every post when the caller is that user.
     */
    @Transactional
    public PageData<PostResponse> getPostsByUser(UUID userId, int page, int size) {
        Page p = validatePage(page, size);
        Viewer viewer = resolveViewer();
        PanacheQuery<Post> query = postRepository.findVisibleByAuthor(userId, viewer.userId(), viewer.friendIds());
        long total = query.count();
        List<PostResponse> content = toResponses(query.page(p).list(), viewer.userId());
        return PageData.of(content, page, size, total);
    }

    /**
     * Returns the identity of the caller: their id (or {@code null} when anonymous) and the ids of
     * their accepted friends, which is what the visibility queries need.
     */
    private Viewer resolveViewer() {
        UUID viewerId = currentUserProvider.getCurrentUserIdOrNull();
        if (viewerId == null) {
            return new Viewer(null, List.of());
        }
        List<UUID> friendIds = friendshipRepository.findFriends(viewerId).stream()
                .map(friendship -> otherSide(friendship, viewerId))
                .filter(Objects::nonNull)
                .distinct()
                .toList();
        return new Viewer(viewerId, friendIds);
    }

    private static UUID otherSide(FriendshipEntity friendship, UUID viewerId) {
        if (viewerId.equals(friendship.getSenderId())) {
            return friendship.getReceiverId();
        }
        if (viewerId.equals(friendship.getReceiverId())) {
            return friendship.getSenderId();
        }
        return null;
    }

    /**
     * Builds the response payloads of a page of posts, filling the real interaction counters and the
     * reaction state of the viewer with one query per interaction type (no per-post query).
     */
    private List<PostResponse> toResponses(List<Post> posts, UUID viewerId) {
        if (posts.isEmpty()) {
            return List.of();
        }
        List<UUID> postIds = posts.stream().map(Post::getId).toList();
        Map<UUID, Integer> reactionCounts = postInteractionService.countReactionsByPost(postIds, null);
        Map<UUID, Integer> commentCounts = postInteractionService.countCommentsByPost(postIds, null);
        Set<UUID> reactedPostIds = postInteractionService.findReactedPostIds(viewerId, postIds);
        Map<UUID, AuthorResponse> authors = authorsOf(posts.stream().map(Post::getAuthorId).toList());
        return posts.stream()
                .map(post -> PostResponse.from(
                        post,
                        authors.getOrDefault(post.getAuthorId(), new AuthorResponse(post.getAuthorId(), null, null)),
                        reactionCounts.getOrDefault(post.getId(), 0),
                        commentCounts.getOrDefault(post.getId(), 0),
                        reactedPostIds.contains(post.getId())))
                .toList();
    }

    /**
     * Builds the response payload of a single post, including its interaction counters.
     */
    private PostResponse toResponse(Post post, UUID viewerId) {
        ReactionSummaryResponse reactions = postInteractionService.summarize(post.getId(), viewerId);
        int commentCount = postInteractionService.countCommentsByPost(List.of(post.getId()), null)
                .getOrDefault(post.getId(), 0);
        return PostResponse.from(
                post,
                authorOf(post.getAuthorId()),
                reactions.total(),
                commentCount,
                reactions.myReaction() != null);
    }

    /**
     * Builds the detail payload: the post itself plus its reactions and its comments.
     */
    private PostDetailResponse toDetail(Post post, UUID viewerId) {
        List<PostComment> comments = postInteractionService.findComments(post.getId());
        ReactionSummaryResponse reactions = postInteractionService.summarize(post.getId(), viewerId);
        PostResponse base = PostResponse.from(
                post,
                authorOf(post.getAuthorId()),
                reactions.total(),
                comments.size(),
                reactions.myReaction() != null);
        return PostDetailResponse.from(
                base,
                reactions,
                comments.stream().map(CommentResponse::from).toList());
    }

    private AuthorResponse authorOf(UUID authorId) {
        return userRepo.findByIdOptional(authorId)
                .map(PostService::toAuthor)
                .orElseGet(() -> new AuthorResponse(authorId, null, null));
    }

    private Map<UUID, AuthorResponse> authorsOf(Collection<UUID> authorIds) {
        Set<UUID> ids = authorIds.stream()
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (ids.isEmpty()) {
            return Map.of();
        }
        return userRepo.list("id in ?1", List.copyOf(ids)).stream()
                .collect(Collectors.toMap(User::getId, PostService::toAuthor));
    }

    private static AuthorResponse toAuthor(User user) {
        return new AuthorResponse(user.getId(), user.getUsername(), user.getAvatar_url());
    }

    private record Viewer(UUID userId, List<UUID> friendIds) {
    }

    private record TrendingCandidate(UUID postId, LocalDateTime createdAt, int score) {
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
