# Konnexus — Module Hội nhóm (Group) — Quarkus Java

Đã thay toàn bộ mã nguồn **Friendship** trong bản ZIP gốc bằng **Group**; giữ lại cấu hình Quarkus, Maven, PostgreSQL, Hibernate Panache, DTO `ApiResponse` và cách chia package `com.meta.junior`.

## Chạy dự án

Yêu cầu JDK 17+, Maven hoặc Maven Wrapper, PostgreSQL. Tạo database `konnexus_db` (hoặc chỉnh `src/main/resources/application.properties`). Cấu hình mật khẩu bằng biến môi trường `DB_PASSWORD` (mặc định là `123456` để tương thích project gốc; **đổi ngay khi dùng ngoài máy cá nhân**).

Windows:

```bat
set DB_PASSWORD=123456
mvnw.cmd quarkus:dev
```

Linux/macOS:

```bash
export DB_PASSWORD=123456
./mvnw quarkus:dev
```

Các bảng mới được Hibernate tạo/cập nhật theo `quarkus.hibernate-orm.schema-management.strategy=update`:

- `konnexus_groups` — tên, mô tả, quyền riêng tư, chủ nhóm, ảnh bìa, `require_post_approval`, `deleted_at` (xóa mềm)
- `group_members` — thành viên và vai trò `OWNER`, `ADMIN`, `MEMBER`
- `group_join_requests` — yêu cầu tham gia `PENDING`, `APPROVED`, `REJECTED`, `CANCELED`
- `group_posts` — bài viết `PENDING`, `PUBLISHED`, `REJECTED`, `deleted_at` (xóa mềm)

**Lưu ý:** Việc xóa file mã nguồn Friendship **không tự DROP bảng `friendship`** đã tồn tại trong PostgreSQL; Hibernate `update` không xóa bảng cũ. Nếu thực sự muốn xóa dữ liệu đó, hãy sao lưu và chủ động chạy `DROP TABLE IF EXISTS friendship;` tại môi trường phù hợp.

## Xác định người dùng khi test

Khi chạy **dev/test**, thêm header `X-Test-User-Id: <UUID>` cho API yêu cầu đăng nhập. Ví dụ:

```http
X-Test-User-Id: 11111111-1111-1111-1111-111111111111
```

Ở chế độ chạy production (`NORMAL`), header test bị **vô hiệu hóa**; API ghi dữ liệu chỉ hoạt động nếu ứng dụng cấp `SecurityIdentity` xác thực, với `principal.name` là UUID. Bạn phải cấu hình JWT/xác thực thật trước khi triển khai. Không dùng header ID tự khai trong production. API đọc nhóm PUBLIC được truy cập không cần header.

## Danh sách API

| Phương thức | Endpoint | Quyền |
|---|---|---|
| POST | `/api/groups` | Người dùng |
| GET | `/api/groups?keyword=...` | Công khai |
| GET | `/api/groups/mine` | Người dùng |
| GET | `/api/groups/{groupId}` | Công khai |
| PUT | `/api/groups/{groupId}` | OWNER/ADMIN |
| PUT | `/api/groups/{groupId}/delete` | OWNER (xóa mềm) |
| POST | `/api/groups/{groupId}/join` | Người dùng (PUBLIC tham gia ngay; PRIVATE chờ duyệt) |
| GET | `/api/groups/{groupId}/membership` | Người dùng |
| DELETE | `/api/groups/{groupId}/join` | Hủy yêu cầu đang chờ |
| GET | `/api/groups/{groupId}/requests` | OWNER/ADMIN |
| PUT | `/api/groups/{groupId}/requests/{requestId}/approve` | OWNER/ADMIN |
| PUT | `/api/groups/{groupId}/requests/{requestId}/reject` | OWNER/ADMIN |
| GET | `/api/groups/{groupId}/members` | Công khai nếu PUBLIC, thành viên nếu PRIVATE |
| DELETE | `/api/groups/{groupId}/members/me` | Rời nhóm, trừ OWNER |
| DELETE | `/api/groups/{groupId}/members/{userId}` | OWNER/ADMIN có giới hạn quyền |
| PUT | `/api/groups/{groupId}/members/{userId}/promote` | OWNER |
| PUT | `/api/groups/{groupId}/members/{userId}/demote` | OWNER |
| PUT | `/api/groups/{groupId}/owner/{userId}` | OWNER, chuyển quyền cho thành viên hiện có |
| POST | `/api/groups/{groupId}/posts` | Thành viên |
| GET | `/api/groups/{groupId}/posts` | PUBLIC công khai; PRIVATE thành viên |
| GET | `/api/groups/{groupId}/posts/mine` | Thành viên |
| GET | `/api/groups/{groupId}/posts/pending` | OWNER/ADMIN |
| PUT | `/api/groups/{groupId}/posts/{postId}` | Tác giả |
| PUT | `/api/groups/{groupId}/posts/{postId}/approve` | OWNER/ADMIN |
| PUT | `/api/groups/{groupId}/posts/{postId}/reject` | OWNER/ADMIN |
| PUT | `/api/groups/{groupId}/posts/{postId}/delete` | Tác giả/OWNER/ADMIN (xóa mềm) |

**Điều chỉnh hai API xóa mềm:** chỉ `PUT /api/groups/{groupId}/delete` và
`PUT /api/groups/{groupId}/posts/{postId}/delete` thay cho các endpoint `DELETE` cũ.
Cả hai không yêu cầu request body; dữ liệu được giữ trong cơ sở dữ liệu và ẩn khỏi
các API danh sách/chi tiết. Các API còn lại (kể cả `DELETE` xóa thành viên, rời nhóm)
không thay đổi.

Tất cả API trả về cấu trúc `ApiResponse`: `{"success":true,"message":"...","data":...}`. Mã phản hồi: `201` khi tạo, `200` khi thành công, `400` dữ liệu sai, `401` chưa đăng nhập, `403` thiếu quyền, `404` không thấy, `409` xung đột trạng thái.

### Request mẫu: tạo nhóm

```http
POST http://localhost:8080/api/groups
Content-Type: application/json
X-Test-User-Id: 11111111-1111-1111-1111-111111111111

{
  "name": "Hội nhóm lập trình Java",
  "description": "Chia sẻ kinh nghiệm Quarkus",
  "privacy": "PRIVATE",
  "coverUrl": "https://example.com/cover.png",
  "requirePostApproval": true
}
```

### Request mẫu: tạo bài viết

```http
POST http://localhost:8080/api/groups/{groupId}/posts
Content-Type: application/json
X-Test-User-Id: 11111111-1111-1111-1111-111111111111

{"content": "Chào mọi người!"}
```

Nhóm PRIVATE: người dùng gửi `POST /join`, OWNER/ADMIN xem `GET /requests` rồi `PUT .../approve`; sau đó mới đăng bài. Khi `requirePostApproval=true`, bài của MEMBER ở trạng thái `PENDING` cho tới khi OWNER/ADMIN duyệt.

## Kiểm thử

Project bao gồm `src/test/java/com/meta/junior/GroupApiTest.java` với các luồng: nhóm công khai, nhóm riêng tư, duyệt thành viên, duyệt bài, xóa mềm, chuyển chủ nhóm, validate. Cấu hình test dùng H2 memory theo `src/test/resources/application.properties`, không yêu cầu PostgreSQL:

```bat
mvnw.cmd test
```

## Phạm vi

Module độc lập theo nhóm, tham chiếu `UUID userId` từ hệ thống tài khoản Konnexus; **không có bảng user mới** và không giả lập tích hợp module Post chung. Mục đích: tạo backend hội nhóm có thể tích hợp vào mạng xã hội sau này.
