package com.meta.junior;

import com.meta.junior.common.PostPrivacy;
import com.meta.junior.entity.Emoji;
import com.meta.junior.entity.Post;
import com.meta.junior.entity.PostComment;
import com.meta.junior.entity.PostMedia;
import com.meta.junior.friendship.entity.FriendshipEntity;
import com.meta.junior.friendship.repository.FriendshipRepository;
import com.meta.junior.repository.EmojiRepository;
import com.meta.junior.repository.PostCommentRepository;
import com.meta.junior.repository.PostRepository;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasItems;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.nullValue;

/**
 * Privacy, trending and PUT-based soft delete behaviour of the Post API.
 *
 * <p>The fixture is seeded directly in the database by a transactional {@code @BeforeEach} (so it is
 * committed before any HTTP call) and covers every visibility case:</p>
 * <ul>
 *   <li>{@code AUTHOR} owns a PUBLIC, a FRIENDS, a PRIVATE and a soft-deleted post,</li>
 *   <li>{@code FRIEND} is an accepted friend of {@code AUTHOR},</li>
 *   <li>{@code PENDING_FRIEND} only has a pending request,</li>
 *   <li>{@code STRANGER} is unrelated and owns two PUBLIC posts.</li>
 * </ul>
 */
@QuarkusTest
class PostPrivacyTest {

    private static final UUID AUTHOR = UUID.fromString("aaaaaaaa-0000-0000-0000-000000000001");
    private static final UUID FRIEND = UUID.fromString("bbbbbbbb-0000-0000-0000-000000000002");
    private static final UUID STRANGER = UUID.fromString("cccccccc-0000-0000-0000-000000000003");
    private static final UUID PENDING_FRIEND = UUID.fromString("dddddddd-0000-0000-0000-000000000004");
    private static final UUID RANDOM_ID = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");

    @Inject
    PostRepository postRepository;

    @Inject
    FriendshipRepository friendshipRepository;

    @Inject
    EmojiRepository emojiRepository;

    @Inject
    PostCommentRepository postCommentRepository;

    private String publicPostId;
    private String friendsPostId;
    private String privatePostId;
    private String deletedPostId;
    private String strangerPost1Id;
    private String strangerPost2Id;

    @BeforeEach
    @Transactional
    void seed() {
        cleanUp();

        LocalDateTime now = LocalDateTime.now();
        Post publicPost = newPost(AUTHOR, "A public post", PostPrivacy.PUBLIC, now.minusHours(5));
        Post friendsPost = newPost(AUTHOR, "A friends post", PostPrivacy.FRIENDS, now.minusHours(4));
        Post privatePost = newPost(AUTHOR, "A private post", PostPrivacy.PRIVATE, now.minusHours(3));
        Post deletedPost = newPost(AUTHOR, "A deleted post", PostPrivacy.PUBLIC, now.minusHours(2));
        Post strangerPost1 = newPost(STRANGER, "Stranger post 1", PostPrivacy.PUBLIC, now.minusHours(6));
        Post strangerPost2 = newPost(STRANGER, "Stranger post 2", PostPrivacy.PUBLIC, now.minusHours(7));
        postRepository.flush();

        publicPostId = publicPost.getId().toString();
        friendsPostId = friendsPost.getId().toString();
        privatePostId = privatePost.getId().toString();
        deletedPostId = deletedPost.getId().toString();
        strangerPost1Id = strangerPost1.getId().toString();
        strangerPost2Id = strangerPost2.getId().toString();

        deletedPost.setStatus(Boolean.FALSE);

        // publicPost: 2 recent reactions, 1 active comment and 1 deleted comment.
        react(publicPost, FRIEND, "LIKE", now.minusHours(1));
        react(publicPost, STRANGER, "LOVE", now.minusMinutes(30));
        comment(publicPost, "Nice post", true, now.minusMinutes(20));
        comment(publicPost, "Deleted comment", false, now.minusMinutes(10));

        // friendsPost: FRIEND reacted, so FRIEND sees _liked = true.
        react(friendsPost, FRIEND, "LIKE", now.minusMinutes(5));

        // privatePost: 4 reactions older than 40 days, i.e. outside the default 7 day trending window.
        react(privatePost, FRIEND, "LIKE", now.minusDays(40));
        react(privatePost, STRANGER, "LIKE", now.minusDays(40));
        react(privatePost, AUTHOR, "LOVE", now.minusDays(40));
        react(privatePost, FRIEND, "WOW", now.minusDays(40));

        // strangerPost1: 2 recent comments (inside the trending window) and 1 old reaction (outside it).
        comment(strangerPost1, "Recent comment", true, now.minusMinutes(45));
        comment(strangerPost1, "Another recent comment", true, now.minusMinutes(40));
        react(strangerPost1, AUTHOR, "LIKE", now.minusDays(40));

        befriend(AUTHOR, FRIEND);
        friendRequest(PENDING_FRIEND, AUTHOR);
    }

    @Transactional
    void cleanUp() {
        emojiRepository.deleteAll();
        postCommentRepository.deleteAll();
        PostMedia.deleteAll();
        postRepository.deleteAll();
        friendshipRepository.deleteAll();
    }

    private Post newPost(UUID authorId, String content, PostPrivacy privacy, LocalDateTime createdAt) {
        Post post = new Post();
        post.setAuthorId(authorId);
        post.setContent(content);
        post.setPrivacy(privacy);
        post.setStatus(Boolean.TRUE);
        post.setCreatedAt(createdAt);
        post.setUpdatedAt(createdAt);
        postRepository.persist(post);
        return post;
    }

    private void react(Post post, UUID authorId, String type, LocalDateTime createdAt) {
        Emoji emoji = new Emoji();
        emoji.emojiType = type;
        emoji.postId = post.getId();
        emoji.authorId = authorId;
        emoji.createdAt = createdAt;
        emojiRepository.persist(emoji);
    }

    private void comment(Post post, String content, boolean active, LocalDateTime createdAt) {
        PostComment postComment = new PostComment();
        postComment.postId = post.getId();
        postComment.content = content;
        postComment.status = active;
        postComment.createdAt = createdAt;
        postCommentRepository.persist(postComment);
    }

    private void befriend(UUID senderId, UUID receiverId) {
        persistFriendship(senderId, receiverId, FriendshipEntity.ACCEPTED);
    }

    private void friendRequest(UUID senderId, UUID receiverId) {
        persistFriendship(senderId, receiverId, FriendshipEntity.PENDING);
    }

    private void persistFriendship(UUID senderId, UUID receiverId, String status) {
        FriendshipEntity friendship = new FriendshipEntity();
        friendship.setSenderId(senderId);
        friendship.setReceiverId(receiverId);
        friendship.setStatus(status);
        friendshipRepository.persist(friendship);
    }

    private static Map<String, Object> updateBody(String content, String privacy) {
        Map<String, Object> body = new LinkedHashMap<>();
        if (content != null) {
            body.put("content", content);
        }
        if (privacy != null) {
            body.put("privacy", privacy);
        }
        return body;
    }
    private static Map<String, Object> deleteBody() {
        return Map.of("status", "DELETED");
    }


    // ---------- Feed (GET /api/v1/posts) ----------

    // 1. An anonymous visitor only sees PUBLIC posts.
    @Test
    void feedWithoutHeaderShowsOnlyPublicPosts() {
        given()
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(3))
                .body("data.total_elements", equalTo(3))
                .body("data.content.id", hasItem(publicPostId))
                .body("data.content.id", not(hasItem(friendsPostId)))
                .body("data.content.id", not(hasItem(privatePostId)))
                .body("data.content.id", not(hasItem(deletedPostId)));
    }

    // 2. A stranger never sees the FRIENDS or PRIVATE posts of another user.
    @Test
    void feedHidesFriendsAndPrivatePostsFromStrangers() {
        given()
                .header("X-User-Id", STRANGER.toString())
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(3))
                .body("data.content.id", hasItems(publicPostId, strangerPost1Id, strangerPost2Id))
                .body("data.content.id", not(hasItem(friendsPostId)))
                .body("data.content.id", not(hasItem(privatePostId)))
                .body("data.content.id", not(hasItem(deletedPostId)));
    }

    // 3. An accepted friend additionally sees the FRIENDS posts, never the PRIVATE ones.
    @Test
    void feedShowsFriendsPostsToAcceptedFriend() {
        given()
                .header("X-User-Id", FRIEND.toString())
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(4))
                .body("data.content.id", hasItems(friendsPostId, publicPostId))
                .body("data.content.id", not(hasItem(privatePostId)))
                .body("data.content.id", not(hasItem(deletedPostId)));
    }

    // 4. The author sees all of their own posts (any privacy) but no soft-deleted one.
    @Test
    void feedShowsOwnPostsWithAnyPrivacyToTheAuthor() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(5))
                .body("data.content.id", hasItems(privatePostId, friendsPostId, publicPostId))
                .body("data.content.id", not(hasItem(deletedPostId)))
                .body("data.content[0].id", equalTo(privatePostId))
                .body("data.content[0].privacy", equalTo("PRIVATE"));
    }

    // 5. A pending friendship grants no extra visibility.
    @Test
    void feedDoesNotShowFriendsPostsToPendingFriend() {
        given()
                .header("X-User-Id", PENDING_FRIEND.toString())
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(3))
                .body("data.content.id", not(hasItem(friendsPostId)))
                .body("data.content.id", not(hasItem(privatePostId)));
    }

    // 6. The real interaction totals are exposed in the list.
    @Test
    void feedExposesInteractionCounters() {
        given()
                .header("X-User-Id", STRANGER.toString())
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.find { it.id == '" + publicPostId + "' }.like_count", equalTo(2))
                .body("data.content.find { it.id == '" + publicPostId + "' }.comment_count", equalTo(1))
                .body("data.content.find { it.id == '" + publicPostId + "' }._liked", equalTo(true))
                .body("data.content.find { it.id == '" + publicPostId + "' }.author.id",
                        equalTo(AUTHOR.toString()));
    }

    // ---------- Posts of a user (GET /api/v1/users/{id}/posts) ----------

    // 7. The posts of a user are filtered by the privacy rules of the caller.
    @Test
    void userPostsRespectPrivacyOfTheCaller() {
        given()
                .header("X-User-Id", STRANGER.toString())
                .when().get("/api/v1/users/" + AUTHOR + "/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(1))
                .body("data.content[0].id", equalTo(publicPostId));

        given()
                .header("X-User-Id", FRIEND.toString())
                .when().get("/api/v1/users/" + AUTHOR + "/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(2))
                .body("data.content.id", hasItems(publicPostId, friendsPostId));

        given()
                .header("X-User-Id", AUTHOR.toString())
                .when().get("/api/v1/users/" + AUTHOR + "/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(3))
                .body("data.content.id", hasItems(publicPostId, friendsPostId, privatePostId));
    }


    // ---------- Post detail (GET /api/v1/posts/{id}) ----------

    // 8. A guest can load a PUBLIC post with its reactions and active comments.
    @Test
    void getPublicPostDetailAsGuestSucceeds() {
        given()
                .when().get("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.id", equalTo(publicPostId))
                .body("data.privacy", equalTo("PUBLIC"))
                .body("data.author.id", equalTo(AUTHOR.toString()))
                .body("data.like_count", equalTo(2))
                .body("data.comment_count", equalTo(1))
                .body("data._liked", equalTo(false))
                .body("data.reactions.total", equalTo(2))
                .body("data.reactions.by_type.LIKE", equalTo(1))
                .body("data.reactions.by_type.LOVE", equalTo(1))
                .body("data.reactions.my_reaction", nullValue())
                .body("data.comments.size()", equalTo(1))
                .body("data.comments[0].content", equalTo("Nice post"))
                .body("data.media_list.size()", equalTo(0));
    }

    // 9. A PRIVATE post is a 404 for everybody but its author.
    @Test
    void getPrivatePostIsForbiddenForOthers() {
        given()
                .header("X-User-Id", FRIEND.toString())
                .when().get("/api/v1/posts/" + privatePostId)
                .then()
                .statusCode(404)
                .body("code", equalTo("NOT_FOUND"));

        given()
                .header("X-User-Id", STRANGER.toString())
                .when().get("/api/v1/posts/" + privatePostId)
                .then()
                .statusCode(404);

        given()
                .when().get("/api/v1/posts/" + privatePostId)
                .then()
                .statusCode(404);

        given()
                .header("X-User-Id", AUTHOR.toString())
                .when().get("/api/v1/posts/" + privatePostId)
                .then()
                .statusCode(200)
                .body("data.privacy", equalTo("PRIVATE"))
                .body("data.like_count", equalTo(4))
                .body("data.reactions.total", equalTo(4))
                .body("data._liked", equalTo(true))
                .body("data.reactions.my_reaction", equalTo("LOVE"));
    }

    // 10. A FRIENDS post is visible to friends only and reports the viewer reaction.
    @Test
    void getFriendsPostDetailIsVisibleToFriendsOnly() {
        given()
                .header("X-User-Id", FRIEND.toString())
                .when().get("/api/v1/posts/" + friendsPostId)
                .then()
                .statusCode(200)
                .body("data.privacy", equalTo("FRIENDS"))
                .body("data._liked", equalTo(true))
                .body("data.reactions.my_reaction", equalTo("LIKE"))
                .body("data.reactions.total", equalTo(1));

        given()
                .header("X-User-Id", STRANGER.toString())
                .when().get("/api/v1/posts/" + friendsPostId)
                .then()
                .statusCode(404);

        given()
                .header("X-User-Id", PENDING_FRIEND.toString())
                .when().get("/api/v1/posts/" + friendsPostId)
                .then()
                .statusCode(404);

        given()
                .when().get("/api/v1/posts/" + friendsPostId)
                .then()
                .statusCode(404);
    }

    // 11. A soft-deleted post is a 404 even for its author.
    @Test
    void getDeletedPostIsNotFound() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .when().get("/api/v1/posts/" + deletedPostId)
                .then()
                .statusCode(404);
    }

    // ---------- Trending (GET /api/v1/posts/trending) ----------

    // 12. Trending never leaks a post the caller may not see.
    @Test
    void trendingRespectsPrivacy() {
        given()
                .header("X-User-Id", STRANGER.toString())
                .when().get("/api/v1/posts/trending")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(3))
                .body("data.total_elements", equalTo(3))
                .body("data.content.id", hasItems(publicPostId, strangerPost1Id, strangerPost2Id))
                .body("data.content.id", not(hasItem(privatePostId)))
                .body("data.content.id", not(hasItem(friendsPostId)))
                .body("data.content.id", not(hasItem(deletedPostId)))
                // publicPost: 2 reactions + 1 comment, strangerPost1: 2 comments, strangerPost2: none.
                .body("data.content[0].id", equalTo(publicPostId))
                .body("data.content[1].id", equalTo(strangerPost1Id))
                .body("data.content[2].id", equalTo(strangerPost2Id));
    }

    // 13. Trending ranks the visible posts by the interactions received inside the window.
    @Test
    void trendingUsesTheRequestedWindow() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .queryParam("days", 60)
                .when().get("/api/v1/posts/trending")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(5))
                .body("data.content.id", not(hasItem(deletedPostId)))
                // privatePost has 4 old reactions, all inside a 60 day window.
                .body("data.content[0].id", equalTo(privatePostId));

        given()
                .header("X-User-Id", AUTHOR.toString())
                .queryParam("days", 7)
                .when().get("/api/v1/posts/trending")
                .then()
                .statusCode(200)
                // The 40 day old reactions fall outside the default window, so publicPost wins.
                .body("data.content[0].id", equalTo(publicPostId))
                .body("data.content[1].id", equalTo(strangerPost1Id));
    }

    // 14. Invalid trending parameters -> 400.
    @Test
    void trendingRejectsInvalidParameters() {
        given()
                .queryParam("days", 0)
                .when().get("/api/v1/posts/trending")
                .then()
                .statusCode(400);

        given()
                .queryParam("days", 400)
                .when().get("/api/v1/posts/trending")
                .then()
                .statusCode(400);

        given()
                .queryParam("page", -1)
                .when().get("/api/v1/posts/trending")
                .then()
                .statusCode(400);
    }

    // ---------- Soft delete through PUT /api/v1/posts/{id} ----------

    // 15. The author soft deletes a post by sending {"status": "DELETED"}.
    @Test
    void putWithDeletedStatusSoftDeletesThePost() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .contentType(ContentType.JSON)
                .body(deleteBody())
                .when().put("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data", nullValue());

        given()
                .when().get("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(404);

        given()
                .header("X-User-Id", AUTHOR.toString())
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(4))
                .body("data.content.id", not(hasItem(publicPostId)));
    }

    // 16. A non-author cannot soft delete somebody else's post.
    @Test
    void putWithDeletedStatusByNonAuthorFails() {
        given()
                .header("X-User-Id", STRANGER.toString())
                .contentType(ContentType.JSON)
                .body("{\"status\":\"DELETED\"}")
                .when().put("/api/v1/posts/" + friendsPostId)
                .then()
                .statusCode(403);

        given()
                .header("X-User-Id", FRIEND.toString())
                .when().get("/api/v1/posts/" + friendsPostId)
                .then()
                .statusCode(200);
    }

    // 17. Deleting an unknown post -> 404.
    @Test
    void putWithDeletedStatusOnUnknownPostFails() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .contentType(ContentType.JSON)
                .body("{\"status\":\"DELETED\"}")
                .when().put("/api/v1/posts/" + RANDOM_ID)
                .then()
                .statusCode(404);
    }

    // 18. The removed DELETE verb is not routed anymore.
    @Test
    void deleteVerbIsNoLongerSupported() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .when().delete("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(405);
    }

    // 19. An update still works and still requires privacy, as well as an authenticated author.
    @Test
    void putUpdatesThePostAndRequiresPrivacy() {
        given()
                .header("X-User-Id", AUTHOR.toString())
                .contentType(ContentType.JSON)
                .body(updateBody("Updated public post", "PUBLIC"))
                .when().put("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(200)
                .body("data.content", equalTo("Updated public post"))
                .body("data.privacy", equalTo("PUBLIC"))
                .body("data.edited", equalTo(true));

        given()
                .header("X-User-Id", AUTHOR.toString())
                .contentType(ContentType.JSON)
                .body(updateBody("Updated public post", null))
                .when().put("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(400);

        given()
                .contentType(ContentType.JSON)
                .body(updateBody("Anonymous update", "PUBLIC"))
                .when().put("/api/v1/posts/" + publicPostId)
                .then()
                .statusCode(401);
    }

}
