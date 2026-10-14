package com.meta.junior;

import com.meta.junior.entity.PostMedia;
import com.meta.junior.repository.PostRepository;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
class PostResourceTest {

    private static final UUID AUTHOR_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID AUTHOR_B = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID RANDOM_ID = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");

    @Inject
    PostRepository postRepository;

    @BeforeEach
    @Transactional
    void cleanUp() {
        // Delete children first to satisfy the post_media -> post foreign key.
        PostMedia.deleteAll();
        postRepository.deleteAll();
    }

    private static Map<String, Object> media(String mediaUrl, String mediaType, int displayOrder) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("media_url", mediaUrl);
        map.put("media_type", mediaType);
        map.put("display_order", displayOrder);
        return map;
    }

    private static Map<String, Object> body(String content, String privacy, List<Map<String, Object>> mediaList) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("content", content);
        map.put("privacy", privacy);
        map.put("media_list", mediaList);
        return map;
    }

    private static String createPost(UUID author, String content, String privacy) {
        return createPost(author, content, privacy, null);
    }

    private static String createPost(UUID author, String content, String privacy, List<Map<String, Object>> mediaList) {
        return given()
                .header("X-User-Id", author.toString())
                .contentType(ContentType.JSON)
                .body(body(content, privacy, mediaList))
                .when().post("/api/v1/posts")
                .then().statusCode(201)
                .extract().path("data.id");
    }

    // 1. Create post success (content + media_list) -> envelope contract
    @Test
    void createPostSucceeds() {
        List<Map<String, Object>> mediaList = new ArrayList<>();
        mediaList.add(media("https://example.com/image.jpg", "IMAGE", 0));

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("Hello Konnexus", "PUBLIC", mediaList))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(201)
                .body("success", equalTo(true))
                .body("message", notNullValue())
                .body("data.id", notNullValue())
                .body("data.author.id", equalTo(AUTHOR_A.toString()))
                .body("data.content", equalTo("Hello Konnexus"))
                .body("data.privacy", equalTo("PUBLIC"))
                .body("data.like_count", equalTo(0))
                .body("data.comment_count", equalTo(0))
                .body("data.edited", equalTo(false))
                .body("data._liked", equalTo(false))
                .body("data.created_at", notNullValue())
                .body("data.updated_at", notNullValue())
                .body("data.media_list.size()", equalTo(1))
                .body("data.media_list[0].id", notNullValue())
                .body("data.media_list[0].media_url", equalTo("https://example.com/image.jpg"))
                .body("data.media_list[0].media_type", equalTo("IMAGE"))
                .body("data.media_list[0].display_order", equalTo(0));
    }

    // 2. Create post with media only (no content) succeeds
    @Test
    void createPostWithMediaOnlySucceeds() {
        List<Map<String, Object>> mediaList = new ArrayList<>();
        mediaList.add(media("https://example.com/a.png", "IMAGE", 0));
        mediaList.add(media("https://example.com/b.mp4", "VIDEO", 1));

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body(null, "PUBLIC", mediaList))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(201)
                .body("success", equalTo(true))
                .body("data.media_list.size()", equalTo(2))
                .body("data.media_list[0].media_type", equalTo("IMAGE"))
                .body("data.media_list[1].media_type", equalTo("VIDEO"));
    }

    // 3. Create post with neither content nor media -> 400
    @Test
    void createPostWithoutContentOrMediaFails() {
        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("", "PUBLIC", List.of()))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400);
    }

    // 4. Get post list (newest first)
    @Test
    void getPostsReturnsNewestFirst() {
        createPost(AUTHOR_A, "First Post", "PUBLIC");
        createPost(AUTHOR_A, "Second Post", "PUBLIC");

        given()
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.content.size()", equalTo(2))
                .body("data.page", equalTo(0))
                .body("data.total_elements", equalTo(2))
                .body("data.content[0].content", equalTo("Second Post"))
                .body("data.content[1].content", equalTo("First Post"));
    }

    // 5. Get post by id (the author can read their own FRIENDS post)
    @Test
    void getPostByIdReturnsPost() {
        String id = createPost(AUTHOR_A, "Fetch me", "FRIENDS");

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .when().get("/api/v1/posts/" + id)
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.id", equalTo(id))
                .body("data.content", equalTo("Fetch me"))
                .body("data.privacy", equalTo("FRIENDS"))
                .body("data.author.id", equalTo(AUTHOR_A.toString()))
                .body("data.reactions.total", equalTo(0))
                .body("data.comments.size()", equalTo(0));
    }

    // 6. Get post by unknown id -> 404
    @Test
    void getPostByUnknownIdFails() {
        given()
                .when().get("/api/v1/posts/" + RANDOM_ID)
                .then()
                .statusCode(404)
                .body("code", equalTo("NOT_FOUND"));
    }

    // 7. Update post by author succeeds and marks edited
    @Test
    void updatePostSucceeds() {
        String id = createPost(AUTHOR_A, "Original", "PUBLIC");

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("Updated", "PRIVATE", null))
                .when().put("/api/v1/posts/" + id)
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.id", equalTo(id))
                .body("data.content", equalTo("Updated"))
                .body("data.privacy", equalTo("PRIVATE"))
                .body("data.edited", equalTo(true));
    }

    // 8. Update by a non-author -> 403
    @Test
    void updatePostByNonAuthorFails() {
        String id = createPost(AUTHOR_A, "Owned by A", "PUBLIC");

        given()
                .header("X-User-Id", AUTHOR_B.toString())
                .contentType(ContentType.JSON)
                .body(body("Hacked", "PUBLIC", null))
                .when().put("/api/v1/posts/" + id)
                .then()
                .statusCode(403);
    }

    // 9. Update replaces the whole media_list when provided
    @Test
    void updatePostReplacesMediaList() {
        List<Map<String, Object>> initialMedia = new ArrayList<>();
        initialMedia.add(media("https://example.com/old.png", "IMAGE", 0));
        String id = createPost(AUTHOR_A, "With media", "PUBLIC", initialMedia);

        List<Map<String, Object>> newMedia = new ArrayList<>();
        newMedia.add(media("https://example.com/new.mp4", "VIDEO", 0));

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("With media", "PUBLIC", newMedia))
                .when().put("/api/v1/posts/" + id)
                .then()
                .statusCode(200)
                .body("data.media_list.size()", equalTo(1))
                .body("data.media_list[0].media_url", equalTo("https://example.com/new.mp4"))
                .body("data.media_list[0].media_type", equalTo("VIDEO"));
    }

    // 10. Delete post by author performs a soft delete
    @Test
    void deletePostSucceeds() {
        String id = createPost(AUTHOR_A, "To be deleted", "PUBLIC");

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(Map.of("status", "DELETED"))
                .when().put("/api/v1/posts/" + id)
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("message", containsString("thành công"));

        given()
                .when().get("/api/v1/posts/" + id)
                .then()
                .statusCode(404);

        given()
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(0));
    }

    // 11. Delete by a non-author -> 403
    @Test
    void deletePostByNonAuthorFails() {
        String id = createPost(AUTHOR_A, "Owned by A", "PUBLIC");

        given()
                .header("X-User-Id", AUTHOR_B.toString())
                .contentType(ContentType.JSON)
                .body(Map.of("status", "DELETED"))
                .when().put("/api/v1/posts/" + id)
                .then()
                .statusCode(403);
    }

    // 12. List posts of a user
    @Test
    void getPostsByUserReturnsOnlyThatUser() {
        createPost(AUTHOR_A, "A one", "PUBLIC");
        createPost(AUTHOR_A, "A two", "PUBLIC");
        createPost(AUTHOR_B, "B one", "PUBLIC");

        given()
                .when().get("/api/v1/users/" + AUTHOR_A + "/posts")
                .then()
                .statusCode(200)
                .body("success", equalTo(true))
                .body("data.content.size()", equalTo(2))
                .body("data.total_elements", equalTo(2))
                .body("data.content[0].author.id", equalTo(AUTHOR_A.toString()))
                .body("data.content[1].author.id", equalTo(AUTHOR_A.toString()));
    }

    // 13. Pagination works
    @Test
    void listPostsPaginationWorks() {
        createPost(AUTHOR_A, "P1", "PUBLIC");
        createPost(AUTHOR_A, "P2", "PUBLIC");
        createPost(AUTHOR_A, "P3", "PUBLIC");

        given()
                .queryParam("page", 0).queryParam("size", 2)
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(2))
                .body("data.page", equalTo(0))
                .body("data.size", equalTo(2))
                .body("data.total_elements", equalTo(3))
                .body("data.total_pages", equalTo(2));

        given()
                .queryParam("page", 1).queryParam("size", 2)
                .when().get("/api/v1/posts")
                .then()
                .statusCode(200)
                .body("data.content.size()", equalTo(1));
    }

    // 14. Invalid privacy value -> 400
    @Test
    void createPostWithInvalidPrivacyFails() {
        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("Hello", "SECRET", null))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400);
    }

    // 15. More than 10 media items -> 400
    @Test
    void createPostWithTooManyMediaFails() {
        List<Map<String, Object>> mediaList = new ArrayList<>();
        for (int i = 0; i < 11; i++) {
            mediaList.add(media("https://example.com/" + i + ".png", "IMAGE", i));
        }

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("Many media", "PUBLIC", mediaList))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400);
    }

    // 16. Invalid media_url -> 400
    @Test
    void createPostWithInvalidMediaUrlFails() {
        List<Map<String, Object>> mediaList = new ArrayList<>();
        mediaList.add(media("not-a-url", "IMAGE", 0));

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body("Bad media", "PUBLIC", mediaList))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400);
    }

    // 17. Missing authenticated user header -> 401
    @Test
    void createPostWithoutUserHeaderFails() {
        given()
                .contentType(ContentType.JSON)
                .body(body("No auth", "PUBLIC", null))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(401);
    }

    // 18. Content longer than 5000 characters -> 400
    @Test
    void createPostWithTooLongContentFails() {
        String tooLong = "a".repeat(5001);

        given()
                .header("X-User-Id", AUTHOR_A.toString())
                .contentType(ContentType.JSON)
                .body(body(tooLong, "PUBLIC", null))
                .when().post("/api/v1/posts")
                .then()
                .statusCode(400);
    }

    // 19. Invalid pagination parameters -> 400
    @Test
    void listPostsWithInvalidPaginationFails() {
        given()
                .queryParam("page", -1)
                .when().get("/api/v1/posts")
                .then()
                .statusCode(400);

        given()
                .queryParam("size", 0)
                .when().get("/api/v1/posts")
                .then()
                .statusCode(400);
    }
}
