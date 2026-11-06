package com.meta.junior;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.Matchers.hasItems;

/** Đảm bảo API lời mời gộp và các API GET khác vẫn có profile giả lập. */
@QuarkusTest
class FriendshipGetProfilesTest {
    private static final String A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
    private static final String B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
    private static final String C = "cccccccc-cccc-cccc-cccc-cccccccccccc";
    private static final String D = "dddddddd-dddd-dddd-dddd-dddddddddddd";

    @Test
    void mergedRequestsIncludeBothDirectionsAndUserProfiles() {
        // Hồ sơ giả lập của A/B/C/D đã có sẵn; không cần gọi PUT /test-profiles.

        // A gửi lời mời cho B và C; D gửi lời mời cho A.
        String friendshipB = given().header("X-Test-User-Id", A)
                .when().post("/api/friends/requests/" + B)
                .then().statusCode(200).extract().jsonPath().getString("data.id");
        given().header("X-Test-User-Id", A)
                .when().post("/api/friends/requests/" + C)
                .then().statusCode(200);
        String friendshipD = given().header("X-Test-User-Id", D)
                .when().post("/api/friends/requests/" + A)
                .then().statusCode(200).extract().jsonPath().getString("data.id");

        // Một GET trả cả sent + received. Nội dung không phụ thuộc thứ tự UUID.
        given().header("X-Test-User-Id", A)
                .when().get("/api/friends/requests").then().statusCode(200)
                .body("data.sent.size()", is(2))
                .body("data.sent.receiver.id", hasItems(B, C))
                .body("data.received.size()", is(1))
                .body("data.received[0].sender.id", is(D))
                .body("data.received[0].sender.name", is("Nguyễn Văn D"))
                .body("data.received[0].sender.avatar_url", notNullValue())
                .body("data.received[0].sender.is_online", is(true))
                .body("data.received[0].status", is("PENDING"));

        // Từ góc nhìn C, lời mời của A nằm trong received, sent rỗng.
        given().header("X-Test-User-Id", C)
                .when().get("/api/friends/requests").then().statusCode(200)
                .body("data.sent.size()", is(0))
                .body("data.received.size()", is(1))
                .body("data.received[0].sender.id", is(A))
                .body("data.received[0].sender.name", notNullValue())
                .body("data.received[0].sender.avatar_url", notNullValue())
                .body("data.received[0].sender.is_online", is(false));

        // D hủy lời mời để trạng thái với A quay về NONE.
        given().header("X-Test-User-Id", D)
                .when().delete("/api/friends/requests/" + friendshipD + "/cancel")
                .then().statusCode(200);

        // B chấp nhận; A chỉ còn một lời mời đã gửi đến C.
        given().header("X-Test-User-Id", B)
                .when().put("/api/friends/requests/" + friendshipB + "/accept")
                .then().statusCode(200);
        given().header("X-Test-User-Id", A)
                .when().get("/api/friends/requests").then().statusCode(200)
                .body("data.sent.size()", is(1))
                .body("data.sent[0].receiver.id", is(C))
                .body("data.sent[0].receiver.name", is("Nguyễn Văn C"))
                .body("data.sent[0].receiver.avatar_url", notNullValue())
                .body("data.sent[0].receiver.is_online", is(false))
                .body("data.received.size()", is(0));

        given().header("X-Test-User-Id", A)
                .when().get("/api/friends").then().statusCode(200)
                .body("data[0].id", is(B))
                .body("data[0].name", is("Nguyễn Văn B"))
                .body("data[0].avatar_url", is("https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanB"))
                .body("data[0].is_online", is(true));

        given().header("X-Test-User-Id", A)
                .when().get("/api/friends/status/" + B).then().statusCode(200)
                .body("data.id", is(B))
                .body("data.name", is("Nguyễn Văn B"))
                .body("data.avatar_url", is("https://api.dicebear.com/9.x/initials/svg?seed=NguyenVanB"))
                .body("data.is_online", is(true))
                .body("data.status", is("ACCEPTED"));

        given().header("X-Test-User-Id", A)
                .when().get("/api/friends/status/" + C).then().statusCode(200)
                .body("data.status", is("PENDING"))
                .body("data.direction", is("SENT"));
        given().header("X-Test-User-Id", A)
                .when().get("/api/friends/status/" + D).then().statusCode(200)
                .body("data.id", is(D))
                .body("data.name", is("Nguyễn Văn D"))
                .body("data.avatar_url", notNullValue())
                .body("data.is_online", is(true))
                .body("data.status", is("NONE"));
    }
}
