# GET Friendship và hồ sơ giả lập (Dev/Test)

## Danh sách lời mời (đã gộp)

`GET /api/friends/requests`

Header bắt buộc trong chế độ dev/test: `X-Test-User-Id: <UUID của người đang đăng nhập>`.

Response `data` gồm **hai mảng**:
- `sent`: các lời mời đang chờ (`PENDING`) mà người dùng đã gửi; mỗi bản ghi có `receiver` chứa `id`, `name`, `avatar_url`, `is_online`.
- `received`: các lời mời đang chờ (`PENDING`) gửi đến người dùng; mỗi bản ghi có `sender` chứa 4 thông tin tương tự.

Ví dụ:
```json
{
  "success": true,
  "message": "Lấy danh sách lời mời kết bạn thành công",
  "data": {
    "sent": [{
      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "senderId": "11111111-1111-1111-1111-111111111111",
      "receiverId": "22222222-2222-2222-2222-222222222222",
      "status": "PENDING",
      "statusLabel": "Đang chờ",
      "receiver": {
        "id": "22222222-2222-2222-2222-222222222222",
        "name": "Nguyễn Văn B",
        "avatar_url": "https://api.dicebear.com/9.x/initials/svg?seed=TranThiB",
        "is_online": true
      }
    }],
    "received": []
  }
}
```

Các endpoint `GET /api/friends/requests/sent` và `GET /api/friends/requests/received` đã được **thay thế**, ứng dụng Android chỉ gọi GET chung.

## Những GET khác vẫn giữ nguyên

- `GET /api/friends`: danh sách bạn bè; mỗi người có `id`, `name`, `avatar_url`, `is_online`.
- `GET /api/friends/status/{otherUserId}`: trạng thái quan hệ `NONE`/`PENDING`/`ACCEPTED` cùng 4 trường thông tin người dùng. Nếu `PENDING`, trường `direction` là `SENT` hoặc `RECEIVED`.

## Hồ sơ người dùng có sẵn (không cần tạo qua API)

Khi chạy Quarkus, các profile sau được cố định trong `FriendshipService.java`:

| Người | UUID | Tên | is_online |
|---|---|---|---|
| A | `11111111-1111-1111-1111-111111111111` | Nguyễn Văn A | `true` |
| B | `22222222-2222-2222-2222-222222222222` | Trần Thị B | `true` |
| C | `33333333-3333-3333-3333-333333333333` | Lê Văn C | `false` |
| D | `44444444-4444-4444-4444-444444444444` | Phạm Thị D | `true` |

Còn có 4 UUID `aaaaaaaa-...`, `bbbbbbbb-...`, `cccccccc-...`, `dddddddd-...` dành cho test tự động. Avatar là ảnh tạo bằng DiceBear, trả qua URL được gắn theo từng user. Các profile này có sẵn sau mỗi lần khởi động và không cần Postman tạo riêng.

Ví dụ test từ tài khoản A:
- **POST** `/api/friends/requests/22222222-2222-2222-2222-222222222222` với header `X-Test-User-Id: 11111111-1111-1111-1111-111111111111` để gửi lời mời A -> B.
- Đổi header `X-Test-User-Id` sang UUID của B để chấp nhận bằng `PUT /api/friends/requests/{requestId}/accept`.
- Đổi lại header thành UUID của A rồi gọi `GET /api/friends`, bạn sẽ thấy thông tin của B gồm `id`, `name`, `avatar_url`, `is_online`.
- `GET /api/friends/requests` trả về hai mảng `sent` và `received` của những yêu cầu còn `PENDING`.

**Lưu ý:** Có sẵn profile **không** có nghĩa là có sẵn quan hệ bạn bè. Quan hệ `PENDING` và `ACCEPTED` vẫn phải được tạo/chấp nhận bằng API và lưu trong database. Online chỉ là dữ liệu mẫu, không theo dõi thời gian thực. Người dùng UUID khác 8 profile trên vẫn có tên mặc định `Người dùng ...`.

Đã bỏ API `PUT /api/friends/test-profiles` vì profile được cấu hình sẵn, không cần nhập thêm qua API.

## Chạy test

`./mvnw test -Dtest=FriendshipGetProfilesTest`

Trên PowerShell Windows: `.\mvnw.cmd test -Dtest=FriendshipGetProfilesTest`
