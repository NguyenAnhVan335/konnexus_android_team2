package com.meta.junior;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import org.junit.jupiter.api.Test;

import java.util.Map;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@QuarkusTest
class GroupApiTest {
    private static final String OWNER = "11111111-1111-1111-1111-111111111111";
    private static final String MEMBER = "22222222-2222-2222-2222-222222222222";
    private static final String STRANGER = "33333333-3333-3333-3333-333333333333";

    private String create(String privacy, boolean requireApproval) {
        return given().contentType(ContentType.JSON)
                .header("X-Test-User-Id", OWNER)
                .body(Map.of("name", "Group-" + UUID.randomUUID(), "description", "Nhóm kiểm thử",
                        "privacy", privacy, "requirePostApproval", requireApproval))
                .when().post("/api/groups")
                .then().statusCode(201).body("success", is(true))
                .extract().path("data.id");
    }

    @Test
    void publicGroupJoinsImmediatelyAndOwnerCannotLeave() {
        String groupId = create("PUBLIC", false);
        given().header("X-Test-User-Id", MEMBER)
                .when().post("/api/groups/" + groupId + "/join")
                .then().statusCode(200).body("data.status", is("JOINED"));
        given().header("X-Test-User-Id", OWNER)
                .when().delete("/api/groups/" + groupId + "/members/me")
                .then().statusCode(409).body("success", is(false));
        given().when().get("/api/groups/" + groupId)
                .then().statusCode(200).body("data.memberCount", is(2));
    }

    @Test
    void privateGroupRequiresApprovalAndPostModeration() {
        String groupId = create("PRIVATE", true);
        given().header("X-Test-User-Id", MEMBER)
                .when().post("/api/groups/" + groupId + "/join")
                .then().statusCode(200).body("data.status", is("PENDING"));

        given().header("X-Test-User-Id", MEMBER)
                .when().get("/api/groups/" + groupId + "/posts")
                .then().statusCode(403);

        String requestId = given().header("X-Test-User-Id", OWNER)
                .when().get("/api/groups/" + groupId + "/requests")
                .then().statusCode(200).body("data.size()", is(1))
                .extract().path("data[0].id");
        given().header("X-Test-User-Id", OWNER)
                .when().put("/api/groups/" + groupId + "/requests/" + requestId + "/approve")
                .then().statusCode(200).body("data.role", is("MEMBER"));

        String postId = given().header("X-Test-User-Id", MEMBER)
                .contentType(ContentType.JSON).body(Map.of("content", "Bài chờ duyệt"))
                .when().post("/api/groups/" + groupId + "/posts")
                .then().statusCode(201).body("data.status", is("PENDING"))
                .extract().path("data.id");
        given().header("X-Test-User-Id", MEMBER)
                .when().get("/api/groups/" + groupId + "/posts")
                .then().statusCode(200).body("data.size()", is(0));
        given().header("X-Test-User-Id", OWNER)
                .when().put("/api/groups/" + groupId + "/posts/" + postId + "/approve")
                .then().statusCode(200).body("data.status", is("PUBLISHED"));
        given().header("X-Test-User-Id", MEMBER)
                .when().get("/api/groups/" + groupId + "/posts")
                .then().statusCode(200).body("data.size()", is(1));
    }

    @Test
    void ownerSoftDeleteHidesGroupAndPosts() {
        String groupId = create("PUBLIC", false);
        given().header("X-Test-User-Id", STRANGER)
                .when().put("/api/groups/" + groupId + "/delete")
                .then().statusCode(403);
        given().header("X-Test-User-Id", OWNER)
                .when().put("/api/groups/" + groupId + "/delete")
                .then().statusCode(200);
        given().when().get("/api/groups/" + groupId)
                .then().statusCode(404);
        given().when().get("/api/groups/" + groupId + "/posts")
                .then().statusCode(404);
    }


    @Test
    void softDeletePostByPutHidesPostFromLists() {
        String groupId = create("PUBLIC", false);
        String postId = given().header("X-Test-User-Id", OWNER)
                .contentType(ContentType.JSON).body(Map.of("content", "Bài cần xóa mềm"))
                .when().post("/api/groups/" + groupId + "/posts")
                .then().statusCode(201)
                .extract().path("data.id");

        // Người không phải thành viên không thể xóa bài.
        given().header("X-Test-User-Id", STRANGER)
                .when().put("/api/groups/" + groupId + "/posts/" + postId + "/delete")
                .then().statusCode(403);

        given().header("X-Test-User-Id", OWNER)
                .when().put("/api/groups/" + groupId + "/posts/" + postId + "/delete")
                .then().statusCode(200).body("success", is(true));
        given().when().get("/api/groups/" + groupId + "/posts")
                .then().statusCode(200).body("data.size()", is(0));
        given().header("X-Test-User-Id", OWNER)
                .when().get("/api/groups/" + groupId + "/posts/mine")
                .then().statusCode(200).body("data.size()", is(0));
        given().header("X-Test-User-Id", OWNER)
                .when().put("/api/groups/" + groupId + "/posts/" + postId + "/delete")
                .then().statusCode(404);
    }

    @Test
    void ownerCanTransferOwnershipAndFormerOwnerCanLeave() {
        String groupId = create("PUBLIC", false);
        given().header("X-Test-User-Id", MEMBER)
                .when().post("/api/groups/" + groupId + "/join")
                .then().statusCode(200);
        given().header("X-Test-User-Id", OWNER)
                .when().put("/api/groups/" + groupId + "/owner/" + MEMBER)
                .then().statusCode(200).body("data.ownerId", is(MEMBER));
        given().header("X-Test-User-Id", OWNER)
                .when().delete("/api/groups/" + groupId + "/members/me")
                .then().statusCode(200);
        given().header("X-Test-User-Id", MEMBER)
                .when().put("/api/groups/" + groupId + "/delete")
                .then().statusCode(200);
    }

    @Test
    void validationAndDuplicateJoin() {
        given().header("X-Test-User-Id", OWNER)
                .contentType(ContentType.JSON).body(Map.of("name", "   "))
                .when().post("/api/groups")
                .then().statusCode(400);
        String groupId = create("PUBLIC", false);
        given().header("X-Test-User-Id", OWNER)
                .when().post("/api/groups/" + groupId + "/join")
                .then().statusCode(409);
    }
}
