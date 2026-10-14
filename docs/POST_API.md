# Đặc tả & kịch bản test API Bài viết (v1)

Tài liệu viết theo dạng bảng đặc tả **STT – Tên – Mô tả – Phương thức – API – Tiền Điều Kiện – Input – Output – Lưu ý**, kèm ví dụ request/response đúng như khi bấm **Try it out** trên Swagger UI.

## 0. Chuẩn bị trước khi test

| Hạng mục        | Giá trị                                                                  |
| --------------- | ------------------------------------------------------------------------ |
| Base URL        | `http://localhost:8080`                                                  |
| Swagger UI      | `http://localhost:8080/q/swagger-ui` (chạy `./mvnw quarkus:dev`)          |
| Content-Type    | `application/json`                                                       |
| Header danh tính | `X-User-Id: <UUID>` — **bắt buộc** với `POST` / `PUT`, không bắt buộc với `GET` |
| Enum `privacy`  | `PUBLIC`, `FRIENDS`, `PRIVATE`                                           |
| Enum `status`   | `ACTIVE`, `DELETED`                                                      |
| Enum `media_type` | `IMAGE`, `VIDEO`                                                        |
| Envelope thành công | `{ "success": true, "message": "...", "data": ... }`                  |
| Envelope lỗi    | `{ "status": 404, "code": "NOT_FOUND", "message": "...", "details": [] }` |

Gợi ý chuẩn bị dữ liệu: tạo 2–3 user (UUID tự chọn), 1 quan hệ bạn bè `ACCEPTED` (bảng `friendships`) và 1 quan hệ `PENDING` để test đủ các nhánh quyền riêng tư.

## 1. Bảng tổng hợp các API

| STT | Tên | Mô tả | Phương thức | API | Tiền Điều Kiện | Input | Output | Lưu ý |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Đăng bài viết | Tạo bài viết mới cho người dùng đang đăng nhập | `POST` | `/api/v1/posts` | Có header `X-User-Id`; body có `content` **hoặc** `media_list`; `privacy` bắt buộc | Header + body: `content`, `privacy`, `media_list[]` | `201` + `PostResponse` + header `Location` | Tác giả lấy từ header, client không gửi `author`; `id` của media do server sinh |
| 2 | Bảng tin (feed) | Danh sách bài viết người gọi được phép xem, mới nhất trước | `GET` | `/api/v1/posts` | Không | Query: `page`, `size` | `200` + `PageData<PostResponse>` | Không có header = khách ẩn danh, chỉ thấy bài `PUBLIC` |
| 3 | Bài viết nổi bật | Xếp hạng theo số tương tác nhận được trong `days` ngày gần nhất | `GET` | `/api/v1/posts/trending` | `days` trong 1..365, `size` trong 1..100, `page` ≥ 0 | Query: `page`, `size`, `days` | `200` + `PageData<PostResponse>` | `days`/`page`/`size` sai → `400`; lọc quyền riêng tư **trước** khi xếp hạng |
| 4 | Xem chi tiết bài viết | Trả đầy đủ bài viết + `reactions` + `comments` | `GET` | `/api/v1/posts/{id}` | `{id}` là UUID; bài viết phải được phép xem | Path: `id` | `200` + `PostDetailResponse` (kèm `reactions`, `comments`), `404` | Bài không được phép xem trả `404` y như bài không tồn tại |
| 5 | Cập nhật bài viết | Sửa `content`, `privacy`, `media_list` | `PUT` | `/api/v1/posts/{id}` | Header + là **tác giả** + body có `privacy` | Header + body: `content`, `privacy`, `media_list[]` | `200` + `PostResponse` với `edited = true`; lỗi `400` / `403` / `404` | Gửi `media_list` là **thay thế toàn bộ** danh sách media cũ |
| 6 | Xoá mềm bài viết | Xoá bài viết bằng `status: DELETED` (không dùng verb `DELETE`) | `PUT` | `/api/v1/posts/{id}` | Header + là **tác giả** | Header + body: `{"status": "DELETED"}` | `200` + `data: null`; lỗi `403` / `404` | Gọi `DELETE /api/v1/posts/{id}` → `405` |
| 7 | Bài viết của một người dùng | Các bài viết của `{userId}` mà người gọi được phép xem | `GET` | `/api/v1/users/{userId}/posts` | Không | Path: `userId`; Query: `page`, `size` | `200` + `PageData<PostResponse>` | Dùng cùng ma trận quyền riêng tư như feed |

## 2. Chi tiết từng API

### 2.1. Đăng bài viết

* **STT**: 1
* **Tên**: Đăng bài viết
* **Mô tả**: Tạo bài viết mới cho người dùng đang đăng nhập; tác giả luôn lấy từ header `X-User-Id`.
* **Phương thức**: `POST`
* **API**: `/api/v1/posts`
* **Tiền Điều Kiện**: có header `X-User-Id` (UUID hợp lệ); body có `content` **hoặc** `media_list`; `privacy` bắt buộc.
* **Input**:

```http
POST /api/v1/posts
Content-Type: application/json
X-User-Id: aaaaaaaa-0000-0000-0000-000000000001

{
  "content": "Hello Konnexus",
  "privacy": "PUBLIC",
  "media_list": [
    { "media_url": "https://example.com/a.png", "media_type": "IMAGE", "display_order": 0 }
  ]
}
```

* **Output**: `201 Created`, header `Location: /api/v1/posts/{id}`

```json
{
  "success": true,
  "message": "Đăng bài viết thành công",
  "data": {
    "id": "1ee812e1-fa42-4c50-96a9-415c8c19bf24",
    "author": { "id": "aaaaaaaa-0000-0000-0000-000000000001", "username": null, "avatar_url": null },
    "content": "Hello Konnexus",
    "privacy": "PUBLIC",
    "like_count": 0,
    "comment_count": 0,
    "media_list": [
      { "id": "e2f0...", "media_url": "https://example.com/a.png", "media_type": "IMAGE", "display_order": 0 }
    ],
    "created_at": "2026-10-15T09:12:31.114",
    "updated_at": "2026-10-15T09:12:31.114",
    "edited": false,
    "_liked": false
  }
}
```

* **Lưu ý / kịch bản test**:

| # | Kịch bản | Input | Kết quả mong đợi |
| --- | --- | --- | --- |
| 1.1 | Content + media_list | Như ví dụ trên | `201`, `like_count = 0`, `comment_count = 0`, `edited = false`, `_liked = false`, có header `Location` |
| 1.2 | Chỉ media_list, không có content | `{"privacy":"PUBLIC","media_list":[...]}` | `201` |
| 1.3 | Không có cả content và media_list | `{"privacy":"PUBLIC"}` | `400` — `At least one of content or media_list is required` |
| 1.4 | Thiếu `privacy` | `{"content":"x"}` | `400` — validation `privacy is required` |
| 1.5 | `privacy` sai giá trị | `"privacy": "EVERYONE"` | `400` |
| 1.6 | `content` > 5000 ký tự | 5001 ký tự `a` | `400` |
| 1.7 | `media_list` > 10 phần tử | 11 media | `400` |
| 1.8 | `media_url` rỗng | `""` | `400` |
| 1.9 | `media_url` không phải http/https | `"not-a-url"`, `"ftp://x/a.png"` | `400` — `media_url must be a valid http/https URL` |
| 1.10 | Không gửi header `X-User-Id` | Bỏ header | `401` |
| 1.11 | Header không phải UUID | `X-User-Id: abc` | `400` |
| 1.12 | `display_order` âm | `-1` | `400` |

### 2.2. Lấy bảng tin (feed)

* **STT**: 2
* **Tên**: Bảng tin (feed)
* **Mô tả**: Danh sách bài viết người gọi được phép xem, sắp xếp mới nhất trước; đã lọc quyền riêng tư trong SQL.
* **Phương thức**: `GET`
* **API**: `/api/v1/posts`
* **Tiền Điều Kiện**: không bắt buộc header (không có header = khách ẩn danh).
* **Input**: query `page` (mặc định `0`, ≥ 0), `size` (mặc định `10`, 1..100).

```http
GET /api/v1/posts?page=0&size=10
X-User-Id: bbbbbbbb-0000-0000-0000-000000000002   (tùy chọn)
```

* **Output**: `200` + `PageData<PostResponse>`

```json
{
  "success": true,
  "message": "Lấy danh sách bài viết thành công",
  "data": {
    "content": [ { "id": "...", "author": { }, "content": "...", "privacy": "PUBLIC",
                   "like_count": 2, "comment_count": 1, "media_list": [],
                   "created_at": "...", "updated_at": "...", "edited": false, "_liked": true } ],
    "page": 0, "size": 10, "total_elements": 4, "total_pages": 1
  }
}
```

* **Lưu ý / kịch bản test** (dữ liệu mẫu: `AUTHOR` có bài PUBLIC / FRIENDS / PRIVATE / đã xoá mềm; `STRANGER` có 2 bài PUBLIC):

| # | Người gọi | Kết quả mong đợi |
| --- | --- | --- |
| 2.1 | Khách (không header) | `200`, chỉ thấy 3 bài `PUBLIC`, không thấy bài `FRIENDS` / `PRIVATE` / đã xoá |
| 2.2 | `STRANGER` (người lạ) | `200`, thấy bài `PUBLIC` của mọi người + 2 bài của mình, **không** thấy `FRIENDS` / `PRIVATE` / đã xoá |
| 2.3 | `FRIEND` (đã accept) | `200`, thấy thêm bài `FRIENDS`, vẫn không thấy `PRIVATE` |
| 2.4 | `AUTHOR` | `200`, thấy mọi bài của mình (kể cả `PRIVATE`) nhưng **không** thấy bài đã xoá mềm |
| 2.5 | `PENDING_FRIEND` (chờ kết bạn) | `200`, không thấy bài `FRIENDS` (lời mời chưa accept không có quyền) |
| 2.6 | Kiểm tra counter | `like_count` / `comment_count` là số thật từ bảng `emojis` / `post_comments`; `_liked` đúng theo người gọi; `author.id` là id tác giả |
| 2.7 | Phân trang sai | `?page=-1` hoặc `?size=0` hoặc `?size=101` → `400` |

### 2.3. Lấy bài viết nổi bật (trending)

* **STT**: 3
* **Tên**: Bài viết nổi bật
* **Mô tả**: Các bài viết người gọi được phép xem, xếp hạng theo `số reaction + số comment còn hiệu lực` nhận được trong `days` ngày gần nhất; bằng điểm thì bài mới hơn đứng trước.
* **Phương thức**: `GET`
* **API**: `/api/v1/posts/trending`
* **Tiền Điều Kiện**: `days` trong 1..365 (mặc định `7`), `size` trong 1..100, `page` ≥ 0.
* **Input**: query `page`, `size`, `days`.

```http
GET /api/v1/posts/trending?page=0&size=10&days=7
X-User-Id: cccccccc-0000-0000-0000-000000000003   (tùy chọn)
```

* **Output**: `200` + `PageData<PostResponse>` — thứ tự trong `content` chính là thứ hạng; `data.content[].like_count` là tổng reaction (không giới hạn cửa sổ), còn thứ hạng chỉ tính tương tác trong `days` ngày.

* **Lưu ý / kịch bản test**:

| # | Kịch bản | Kết quả mong đợi |
| --- | --- | --- |
| 3.1 | Người gọi `STRANGER`, mặc định `days=7` | `200`, chỉ 3 bài được phép xem; thứ tự: bài có 2 reaction + 1 comment > bài có 2 comment > bài không có tương tác |
| 3.2 | Người gọi `AUTHOR`, so sánh `days=60` với `days=7` | Với `days=60`: bài `PRIVATE` (4 reaction cách đây 40 ngày) đứng đầu; với `days=7`: bài có tương tác gần đây đứng đầu |
| 3.3 | Không được phép xem | Bài `PRIVATE` / `FRIENDS` của người khác và bài đã xoá mềm **không bao giờ** xuất hiện |
| 3.4 | Tham số sai | `days=0`, `days=400`, `page=-1` → `400` |
| 3.5 | Khách (không header) | `200`, chỉ bài `PUBLIC` |

### 2.4. Xem chi tiết bài viết

* **STT**: 4
* **Tên**: Xem chi tiết bài viết
* **Mô tả**: Trả về đầy đủ một bài viết kèm thông tin tương tác (`reactions`, `comments`).
* **Phương thức**: `GET`
* **API**: `/api/v1/posts/{id}`
* **Tiền Điều Kiện**: `{id}` là UUID của bài viết; bài viết phải còn hoạt động và được phép xem.
* **Input**:

```http
GET /api/v1/posts/1ee812e1-fa42-4c50-96a9-415c8c19bf24
X-User-Id: bbbbbbbb-0000-0000-0000-000000000002   (tùy chọn)
```

* **Output**: `200` + `PostDetailResponse` (= payload bài viết **+** `reactions` **+** `comments`)

```json
{
  "success": true,
  "message": "Lấy bài viết thành công",
  "data": {
    "id": "1ee812e1-fa42-4c50-96a9-415c8c19bf24",
    "author": { "id": "aaaaaaaa-0000-0000-0000-000000000001", "username": null, "avatar_url": null },
    "content": "Hello Konnexus",
    "privacy": "PUBLIC",
    "like_count": 2,
    "comment_count": 1,
    "media_list": [],
    "created_at": "2026-10-15T09:12:31.114",
    "updated_at": "2026-10-15T09:12:31.114",
    "edited": false,
    "_liked": true,
    "reactions": { "total": 2, "by_type": { "LIKE": 1, "LOVE": 1 }, "my_reaction": "LIKE" },
    "comments": [
      {
        "id": "3f4b...",
        "post_id": "1ee812e1-fa42-4c50-96a9-415c8c19bf24",
        "parent_comment_id": null,
        "content": "Nice post",
        "image": null,
        "created_at": "2026-10-15T09:20:02.551"
      }
    ]
  }
}
```

* **Lưu ý / kịch bản test**:

| # | Kịch bản | Người gọi | Kết quả mong đợi |
| --- | --- | --- | --- |
| 4.1 | Bài `PUBLIC` | Khách | `200`; `like_count = 2`, `comment_count = 1` (chỉ đếm comment còn hiệu lực), `_liked = false`, `reactions.total = 2`, `reactions.my_reaction = null`, `comments[]` cũ nhất trước |
| 4.2 | Bài `PRIVATE` | Bạn bè / người lạ / khách | `404`, `code = "NOT_FOUND"` |
| 4.3 | Bài `PRIVATE` | Tác giả | `200`, `privacy = "PRIVATE"`, `reactions.total = 4`, `_liked = true`, `my_reaction = "LOVE"` |
| 4.4 | Bài `FRIENDS` | Bạn bè đã accept | `200`, `privacy = "FRIENDS"`, `_liked = true`, `my_reaction = "LIKE"` |
| 4.5 | Bài `FRIENDS` | Người lạ / lời mời `PENDING` / khách | `404` |
| 4.6 | Bài đã xoá mềm | Tác giả | `404` |
| 4.7 | `id` không tồn tại | Bất kỳ | `404` |
| 4.8 | `id` không phải UUID | Bất kỳ | `404` |

### 2.5. Cập nhật bài viết

* **STT**: 5
* **Tên**: Cập nhật bài viết
* **Mô tả**: Sửa `content`, `privacy` và (tùy chọn) thay toàn bộ `media_list` của bài viết đã có.
* **Phương thức**: `PUT`
* **API**: `/api/v1/posts/{id}`
* **Tiền Điều Kiện**: có header `X-User-Id`; người gọi là **tác giả** bài viết; body **bắt buộc** có `privacy`.
* **Input**:

```http
PUT /api/v1/posts/1ee812e1-fa42-4c50-96a9-415c8c19bf24
Content-Type: application/json
X-User-Id: aaaaaaaa-0000-0000-0000-000000000001

{ "content": "Edited caption", "privacy": "FRIENDS" }
```

* **Output**: `200` + payload bài viết đã cập nhật (`edited = true`, `updated_at` được làm mới)

```json
{
  "success": true,
  "message": "Cập nhật bài viết thành công",
  "data": { "id": "1ee8...", "content": "Edited caption", "privacy": "FRIENDS", "edited": true, "...": "..." }
}
```

* **Lưu ý / kịch bản test**:

| # | Kịch bản | Input | Kết quả mong đợi |
| --- | --- | --- | --- |
| 5.1 | Tác giả sửa content + privacy | `{"content":"Edited","privacy":"FRIENDS"}` | `200`, `data.content = "Edited"`, `data.privacy = "FRIENDS"`, `edited = true` |
| 5.2 | Tác giả gửi `media_list` mới | `{"privacy":"PUBLIC","media_list":[ 1 item ]}` | `200`, danh sách media cũ bị **thay thế hoàn toàn** bằng item mới (id mới do server sinh) |
| 5.3 | Thiếu `privacy` | `{"content":"x"}` | `400` — `privacy is required` |
| 5.4 | Không phải tác giả | `X-User-Id` của user khác | `403` |
| 5.5 | Không gửi header | Bỏ `X-User-Id` | `401` |
| 5.6 | `{id}` không tồn tại | UUID ngẫu nhiên | `404` |
| 5.7 | `{id}` là bài đã xoá mềm | Gửi PUT vào bài `DELETED` | `404` |
| 5.8 | Body rỗng | `{}` | `400` (không có `status` nên được coi là update, mà update thiếu `privacy`) |
| 5.9 | Trường bất biến | Đối chiếu trước/sau | `id`, `author`, `like_count`, `comment_count`, `created_at`, `status` không đổi |

### 2.6. Xoá mềm bài viết (qua `PUT`)

* **STT**: 6
* **Tên**: Xoá mềm bài viết
* **Mô tả**: Xoá bài viết là thay đổi trạng thái nên biểu diễn bằng `PUT` + `status: DELETED`; bản ghi được giữ lại và `status` chuyển thành `false`.
* **Phương thức**: `PUT`
* **API**: `/api/v1/posts/{id}`
* **Tiền Điều Kiện**: có header `X-User-Id`; người gọi là **tác giả**; body chỉ chứa `status`.
* **Input**:

```http
PUT /api/v1/posts/1ee812e1-fa42-4c50-96a9-415c8c19bf24
Content-Type: application/json
X-User-Id: aaaaaaaa-0000-0000-0000-000000000001

{ "status": "DELETED" }
```

* **Output**: `200`, `data = null`

```json
{ "success": true, "message": "Xóa bài viết thành công", "data": null }
```

* **Lưu ý / kịch bản test**:

| # | Kịch bản | Kết quả mong đợi |
| --- | --- | --- |
| 6.1 | Tác giả xoá bài | `200`, `success = true`, `data = null` |
| 6.2 | Sau khi xoá, xem chi tiết bằng chính tác giả | `404` |
| 6.3 | Sau khi xoá, bài biến mất khỏi feed / trending / timeline | `200` nhưng `content` không còn id đó |
| 6.4 | Không phải tác giả xoá | `403`; bạn bè vẫn xem được bài (`200`) — bài **không** bị xoá |
| 6.5 | Xoá bài không tồn tại | `404` |
| 6.6 | Gọi lại lần thứ hai trên cùng bài | `404` (bài đã ở trạng thái xoá) |
| 6.7 | Dùng verb cũ `DELETE /api/v1/posts/{id}` | `405` — endpoint `DELETE` đã bị bỏ |

### 2.7. Danh sách bài viết của một người dùng

* **STT**: 7
* **Tên**: Bài viết của một người dùng
* **Mô tả**: Các bài viết của `{userId}` mà người gọi được phép xem, mới nhất trước.
* **Phương thức**: `GET`
* **API**: `/api/v1/users/{userId}/posts`
* **Tiền Điều Kiện**: không bắt buộc header.
* **Input**: path `userId`; query `page`, `size`.

```http
GET /api/v1/users/aaaaaaaa-0000-0000-0000-000000000001/posts?page=0&size=10
X-User-Id: bbbbbbbb-0000-0000-0000-000000000002   (tùy chọn)
```

* **Output**: `200` + `PageData<PostResponse>`, cùng ma trận quyền riêng tư như feed.

* **Lưu ý / kịch bản test** (dữ liệu mẫu: `AUTHOR` có 1 bài `PUBLIC`, 1 bài `FRIENDS`, 1 bài `PRIVATE`, 1 bài đã xoá):

| # | Người gọi | Kết quả mong đợi |
| --- | --- | --- |
| 7.1 | `STRANGER` | `200`, `data.content.size() = 1` (chỉ bài `PUBLIC`) |
| 7.2 | `FRIEND` | `200`, `data.content.size() = 2` (`PUBLIC` + `FRIENDS`) |
| 7.3 | `AUTHOR` | `200`, `data.content.size() = 3` (không tính bài đã xoá mềm) |
| 7.4 | `userId` không tồn tại | `200` với `content` rỗng (API chưa kiểm tra user có tồn tại) |
| 7.5 | Phân trang sai | `page=-1` hoặc `size=0` → `400` |

## 3. Ma trận quyền riêng tư (áp dụng cho mọi API đọc)

| Privacy của bài | Khách (không header) | Người lạ | Bạn bè đã accept | Lời mời `PENDING` | Tác giả |
| --- | --- | --- | --- | --- | --- |
| `PUBLIC` | xem | xem | xem | xem | xem |
| `FRIENDS` | `404` / không có trong danh sách | `404` / không có | xem | `404` / không có | xem |
| `PRIVATE` | `404` / không có trong danh sách | `404` / không có | `404` / không có | `404` / không có | xem |

* Bài có `status = DELETED` (đã xoá mềm) **không bao giờ** trả về ở bất kỳ endpoint nào, kể cả với tác giả.
* Bộ lọc được áp trong SQL **trước** khi xếp hạng, nên trending cũng không thể lộ bài.
* Bài không được phép xem luôn trả `404` (không phải `403`) để không tiết lộ sự tồn tại của bài.

## 4. Payload dùng chung

### 4.1. `PostResponse` — dùng cho feed, trending, timeline và response của `POST` / `PUT` cập nhật

| Trường | Kiểu | Mô tả |
| --- | --- | --- |
| `id` | UUID | Id bài viết (server sinh) |
| `author` | object | `{ id, username, avatar_url }`; hiện `username` / `avatar_url` có thể `null` |
| `content` | string | Nội dung (có thể `null` nếu bài chỉ có media) |
| `privacy` | enum | `PUBLIC` / `FRIENDS` / `PRIVATE` |
| `like_count` | int | **Số thật** đếm từ bảng `emojis` (không dùng cột denormalized trong bảng `post`) |
| `comment_count` | int | **Số thật** đếm comment còn hiệu lực từ `post_comments` |
| `media_list` | array | `[{ id, media_url, media_type, display_order }]` |
| `created_at` | datetime | Thời điểm tạo |
| `updated_at` | datetime | Thời điểm cập nhật gần nhất |
| `edited` | boolean | `true` sau khi bài được `PUT` cập nhật |
| `_liked` | boolean | Người gọi đã reaction bài này chưa (`false` với khách) |

### 4.2. `PostDetailResponse` — dùng cho `GET /api/v1/posts/{id}`

Là `PostResponse` **+**:

| Trường | Kiểu | Mô tả |
| --- | --- | --- |
| `reactions.total` | int | Tổng số reaction |
| `reactions.by_type` | object | Ví dụ `{ "LIKE": 1, "LOVE": 1 }` |
| `reactions.my_reaction` | string | Reaction của người gọi, `null` nếu là khách hoặc chưa reaction |
| `comments` | array | Comment còn hiệu lực, cũ nhất trước: `{ id, post_id, parent_comment_id, content, image, created_at }` |

### 4.3. `PageData` — `data` của mọi API danh sách

```json
{ "content": [], "page": 0, "size": 10, "total_elements": 4, "total_pages": 1 }
```

### 4.4. `ErrorResponse` — envelope lỗi

| HTTP | `code` | Khi nào |
| --- | --- | --- |
| `400` | `BAD_REQUEST` | Thiếu `privacy`, không có content lẫn media, `media_url` sai, `page`/`size`/`days` sai, header `X-User-Id` không phải UUID |
| `401` | `UNAUTHORIZED` | Gọi `POST` / `PUT` mà không có header `X-User-Id` |
| `403` | `FORBIDDEN` | Sửa / xoá bài của người khác |
| `404` | `NOT_FOUND` | Bài không tồn tại, đã xoá mềm, hoặc không được phép xem |
| `405` | `METHOD_NOT_ALLOWED` | Gọi verb `DELETE` đã bị bỏ |
| `500` | `INTERNAL_SERVER_ERROR` | Lỗi không lường trước |

## 5. Bảng tổng hợp 38 kịch bản test đã chạy

| STT | API | Kịch bản | Input chính | Kết quả mong đợi |
| --- | --- | --- | --- | --- |
| 1 | `POST /api/v1/posts` | Tạo bài có content + media | header + body đầy đủ | `201`, `success = true`, có `data.id` |
| 2 | `POST /api/v1/posts` | Chỉ có `media_list` | body không có `content` | `201` |
| 3 | `POST /api/v1/posts` | Không có content lẫn media | `{"privacy":"PUBLIC"}` | `400` |
| 4 | `GET /api/v1/posts` | Feed sắp xếp mới nhất trước | – | `200`, `content[0]` là bài mới nhất |
| 5 | `GET /api/v1/posts/{id}` | Tác giả đọc bài `FRIENDS` của mình | header tác giả | `200` |
| 6 | `GET /api/v1/posts/{id}` | Id không tồn tại | UUID ngẫu nhiên | `404` |
| 7 | `PUT /api/v1/posts/{id}` | Tác giả cập nhật | `{"content":"Original","privacy":"PUBLIC"}` | `200`, `edited = true` |
| 8 | `PUT /api/v1/posts/{id}` | Người khác cập nhật | header user khác | `403` |
| 9 | `PUT /api/v1/posts/{id}` | Gửi `media_list` mới | 1 media | `200`, media cũ bị thay thế hoàn toàn |
| 10 | `PUT /api/v1/posts/{id}` | Tác giả xoá mềm | `{"status":"DELETED"}` | `200`, `data = null`; sau đó chi tiết `404`, feed không còn |
| 11 | `PUT /api/v1/posts/{id}` | Người khác xoá | header user khác | `403` |
| 12 | `GET /api/v1/users/{userId}/posts` | Chỉ trả bài của `{userId}` | – | `200`, không lẫn bài user khác |
| 13 | `GET /api/v1/posts` | Phân trang | `page`, `size` | `200`, số phần tử và `total_elements` đúng |
| 14 | `POST /api/v1/posts` | `privacy` sai giá trị | `"EVERYONE"` | `400` |
| 15 | `POST /api/v1/posts` | 11 media | `media_list` 11 phần tử | `400` |
| 16 | `POST /api/v1/posts` | `media_url` không hợp lệ | `"not-a-url"` | `400` |
| 17 | `POST /api/v1/posts` | Thiếu header xác thực | bỏ `X-User-Id` | `401` |
| 18 | `POST /api/v1/posts` | `content` > 5000 ký tự | 5001 ký tự | `400` |
| 19 | `GET /api/v1/posts` | Tham số phân trang sai | `page=-1`, `size=0` | `400` |
| 20 | `GET /api/v1/posts` | Khách ẩn danh | không header | `200`, chỉ bài `PUBLIC`, không có `FRIENDS` / `PRIVATE` / đã xoá |
| 21 | `GET /api/v1/posts` | Người lạ | header `STRANGER` | `200`, không có `FRIENDS` / `PRIVATE` / đã xoá |
| 22 | `GET /api/v1/posts` | Bạn bè đã accept | header `FRIEND` | `200`, có thêm bài `FRIENDS`, không có `PRIVATE` |
| 23 | `GET /api/v1/posts` | Tác giả | header `AUTHOR` | `200`, thấy cả bài `PRIVATE`, không thấy bài đã xoá |
| 24 | `GET /api/v1/posts` | Lời mời `PENDING` | header `PENDING_FRIEND` | `200`, không có bài `FRIENDS` |
| 25 | `GET /api/v1/posts` | Kiểm tra counter thật | header `STRANGER` | `like_count = 2`, `comment_count = 1`, `_liked` đúng, `author.id` đúng |
| 26 | `GET /api/v1/users/{userId}/posts` | Lọc theo người gọi | `STRANGER` / `FRIEND` / `AUTHOR` | Lần lượt `1` / `2` / `3` bài |
| 27 | `GET /api/v1/posts/{id}` | Khách đọc bài `PUBLIC` | không header | `200`, `reactions` + `comments` đúng, `_liked = false`, `my_reaction = null` |
| 28 | `GET /api/v1/posts/{id}` | Bài `PRIVATE` | bạn / người lạ / khách → `404`; tác giả → `200` | `reactions.total = 4`, `my_reaction = "LOVE"` khi là tác giả |
| 29 | `GET /api/v1/posts/{id}` | Bài `FRIENDS` | bạn → `200`; người lạ / `PENDING` / khách → `404` | Bạn thấy `_liked = true`, `my_reaction = "LIKE"` |
| 30 | `GET /api/v1/posts/{id}` | Bài đã xoá mềm | header tác giả | `404` |
| 31 | `GET /api/v1/posts/trending` | Không lộ bài ngoài quyền | header `STRANGER` | `200`, 3 bài, đúng thứ tự theo điểm tương tác |
| 32 | `GET /api/v1/posts/trending` | Cửa sổ thời gian | `days=60` so với `days=7` | Thứ hạng thay đổi theo tương tác trong cửa sổ |
| 33 | `GET /api/v1/posts/trending` | Tham số sai | `days=0`, `days=400`, `page=-1` | `400` |
| 34 | `PUT /api/v1/posts/{id}` | Xoá mềm rồi kiểm tra lại | `{"status":"DELETED"}` | Chi tiết `404`, feed giảm 1 bài |
| 35 | `PUT /api/v1/posts/{id}` | Xoá bài của bạn bè | header `STRANGER` | `403`, bạn bè vẫn xem được bài (`200`) |
| 36 | `PUT /api/v1/posts/{id}` | Xoá bài không tồn tại | UUID ngẫu nhiên | `404` |
| 37 | `DELETE /api/v1/posts/{id}` | Verb cũ đã bỏ | header tác giả | `405` |
| 38 | `PUT /api/v1/posts/{id}` | Cập nhật thiếu `privacy` / thiếu header | `{"content":"x"}` | `400` / `401` |

## 6. Cách chạy lại các kịch bản

```bash
./mvnw test -Dtest=PostResourceTest,PostPrivacyTest
```

Kết quả hiện tại: `PostResourceTest` **19/19 pass**, `PostPrivacyTest` **19/19 pass**.

## 7. Điểm còn thiếu (cần lưu ý khi test)

* Bảng `post_comments` chưa có cột tác giả → `comments[]` chưa trả về người bình luận.
* `username` / `avatar_url` trong `author` có thể `null` (phụ thuộc dữ liệu bảng `users`).
* API chưa kiểm tra `X-User-Id` có trỏ tới tài khoản tồn tại / đang hoạt động hay không.
* Reaction và comment mới chỉ ở chế độ đọc trong API này; tạo/sửa thuộc module emoji / comment.
