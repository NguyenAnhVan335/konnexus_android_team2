<div align="center">

<img src="frontend/assets/images/logoKonnexus.png" alt="Konnexus" width="160" />

# Konnexus — Mạng xã hội mini

**Backend Quarkus 3.40.1 (Java 17) · Frontend Flutter (Material 3) · PostgreSQL · JWT · WebSocket · AI chatbot**

[![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Quarkus](https://img.shields.io/badge/Quarkus-3.40.1-4695EB?logo=quarkus&logoColor=white)](https://quarkus.io)
[![Java](https://img.shields.io/badge/Java-17-orange?logo=openjdk&logoColor=white)](https://openjdk.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)

</div>

---

## 1. Giới thiệu

**Konnexus** là đồ án môn học xây dựng một mạng xã hội thu nhỏ theo mô hình client–server,
gồm hai phần nằm trong cùng repository:

| Thành phần | Công nghệ | Thư mục | Cổng |
|---|---|---|---|
| **Backend** | Quarkus 3.40.1, Java 17, Hibernate ORM Panache, PostgreSQL (Neon/local), SmallRye JWT, WebSocket Next, Cloudinary, LangChain4j + Groq | `src/main/java`, `src/main/resources` | `8080` |
| **Frontend** | Flutter (Dart >= 3.4), Material 3, `http`, `shared_preferences`, `cached_network_image`, `share_plus`, `image_picker`, `url_launcher` | `frontend/lib` | — |

> Frontend **không** dùng Bloc/Riverpod/Provider: toàn bộ state dùng
> `ChangeNotifier` + `ListenableBuilder`, service locator là `AppScope` (InheritedWidget).

- Repository: <https://github.com/NguyenAnhVan335/konnexus_android_team2>
- Nhánh phát triển chính: **`vanna`**
- Hướng dẫn cài đặt chi tiết từng bước: **[SETUP.md](SETUP.md)**

---

## 2. Tính năng

| Nhóm | Chức năng |
|---|---|
| **Xác thực** | Đăng ký (kèm xác thực email), đăng nhập JWT, khôi phục phiên, đăng xuất, đổi mật khẩu (kiểm tra mật khẩu hiện tại) |
| **Bài viết** | Bảng tin phân trang + kéo làm mới, Khám phá (trending theo 7/30/365 ngày), tạo/sửa/xoá mềm, quyền riêng tư `PUBLIC` / `FRIENDS` / `PRIVATE`, media upload qua Cloudinary, hashtag, chia sẻ bài |
| **Tương tác** | 6 loại cảm xúc (`LIKE`, `LOVE`, `HAHA`, `WOW`, `SAD`, `ANGRY`), bình luận + trả lời dạng cây, cảm xúc cho bình luận |
| **Bạn bè** | Tìm kiếm người dùng, gửi/nhận lời mời, chấp nhận/từ chối/huỷ, bỏ kết bạn, trạng thái quan hệ |
| **Tin nhắn** | Chat 1-1 và chat nhóm, **realtime qua WebSocket**, trạng thái đang nhập (typing), đã đọc (read receipt), gửi ảnh/tệp, tạo nhóm |
| **Chatbot "Charles"** | Trả lời tự động khi được tag `@charles` trong hội thoại (Groq — `llama-3.3-70b-versatile`) |
| **Thông báo** | Danh sách thông báo, badge số chưa đọc, đánh dấu đã đọc, xoá thông báo |
| **Hồ sơ** | Trang cá nhân (mình/người khác), chỉnh sửa hồ sơ + avatar, lịch sử hoạt động, cài đặt giao diện |
| **Nhóm (Groups)** | Tạo/tham gia nhóm, duyệt yêu cầu thành viên, bài đăng nhóm chờ duyệt, phân quyền thành viên |
| **Quản trị (ADMIN)** | Dashboard thống kê, quản lý người dùng, quản lý phòng chat, bật/tắt chatbot |

---

## 3. Kiến trúc hệ thống

```
┌─────────────────────────────┐
│   Flutter App (Android)     │
│  ChangeNotifier + AppScope  │
└──────────────┬──────────────┘
               │  REST (HTTP + JWT)          WebSocket
               ▼                                  │
┌─────────────────────────────────────────────────┴──────────────┐
│                     Quarkus Backend (:8080)                    │
│  Controller (@Authenticated) → Service (@Transactional)        │
│        → Repository (Panache) → Entity (JPA)                   │
│  WebSocket /chat/{conversation_id}?token=<JWT>                 │
└───────┬───────────────────────┬───────────────────────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
 PostgreSQL (Neon)        Cloudinary (media)      Groq API (AI)
```

- **Bảo mật**: hầu hết endpoint gắn `@Authenticated`; JWT chứa `sub` = UUID người dùng,
  `groups` = `USER`/`ADMIN`. Controller admin dùng `@RolesAllowed("ADMIN")`.
- **Lỗi**: `ApiException` + `ApiExceptionMapper` trả JSON `{message, code?}`.
- **Schema**: Hibernate `schema-management.strategy=update` (chưa dùng Flyway migration).
- **Frontend**: luồng khởi động `main()` → `AppServices.bootstrap()` → `AppScope` →
  `MaterialApp(onGenerateRoute: AppRouter)` → `AppGate` (Splash / Login / MainShell).

---

## 4. Cấu trúc thư mục

```
konnexus_android_team2/
├─ pom.xml                      # Maven / Quarkus backend
├─ mvnw.cmd, mvnw               # Maven wrapper
├─ README.md                    # (file này)
├─ SETUP.md                     # Hướng dẫn cài đặt & chạy chi tiết
├─ src/main/java/com/meta/junior/
│  ├─ controller/               # REST resources (auth, user, post, chat, group, admin...)
│  ├─ service/                  # Nghiệp vụ (+ impl/)
│  ├─ repository/               # Panache repositories
│  ├─ entity/                   # JPA entities
│  ├─ dto/                      # Request/response DTO
│  ├─ common/                   # Enum, ApiResponse, util
│  ├─ exception/                # ApiException + ExceptionMapper
│  └─ websocket/                # ChatWebSocket + WebSocketAuthFilter
├─ src/main/resources/
│  ├─ application.properties    # Cấu hình DB, JWT, CORS, Cloudinary, AI
│  └─ jwt/                      # Khóa ký/xác thực JWT môi trường dev
└─ frontend/
   ├─ pubspec.yaml              # Dependencies + assets
   ├─ android/                  # Cấu hình Android (Gradle, manifest, icon)
   ├─ test/                     # Unit test (ApiClient, models)
   └─ lib/
      ├─ main.dart, app.dart    # Bootstrap + MaterialApp + AppGate
      ├─ config/                # ApiConfig (base URL, timeout)
      ├─ core/                  # ApiClient, JWT utils, AppServices/AppScope, PreferencesStore
      ├─ models/                # Post, User, Comment, Chat, Notification...
      ├─ services/              # Gọi REST + WebSocket
      ├─ state/                 # ChangeNotifier controllers
      ├─ navigation/            # AppRoutes, AppRouter, AppArguments
      ├─ features/              # auth, shell, home, explore, messages, friends,
      │                         # profile, search, notifications, post, admin
      ├─ widgets/               # Widget dùng chung
      ├─ theme/                 # AppColors, AppSpacing, AppTheme
      └─ utils/                 # validators, formatters, share_utils
```

---

## 5. Yêu cầu môi trường

| Công cụ | Phiên bản / ghi chú |
|---|---|
| **JDK** | 17 (Temurin 17.0.x) — backend và Gradle Android đều dùng Java 17 |
| **Maven** | Không cần cài — dùng `mvnw.cmd` (Windows) / `./mvnw` (macOS/Linux) |
| **PostgreSQL** | 14+ (local) hoặc database **Neon** (cloud) |
| **Flutter SDK** | 3.24+ (Dart >= 3.4); đã kiểm chứng với Flutter 3.47.7 / Dart 3.13.5 |
| **Android SDK** | Platform 36, Build-Tools 35, NDK 28.2.13676358, CMake 3.22.1 |
| **Thiết bị** | Android Emulator (API 30+) hoặc điện thoại thật Android 5.0+ |
| **Tài khoản dịch vụ** | Cloudinary (upload media), Groq (chatbot) — có thể bỏ trống nếu không dùng |

---

## 6. Cài đặt nhanh (5 bước)

> Chi tiết đầy đủ, kèm xử lý lỗi: xem **[SETUP.md](SETUP.md)**.

### Bước 1 — Clone mã nguồn

```powershell
git clone https://github.com/NguyenAnhVan335/konnexus_android_team2.git
cd konnexus_android_team2
git checkout vanna
```

### Bước 2 — Tạo database PostgreSQL

```sql
CREATE DATABASE konnexus_db;
CREATE USER konnexus WITH PASSWORD 'konnexus';
GRANT ALL PRIVILEGES ON DATABASE konnexus_db TO konnexus;
```

> Dùng Neon: tạo project → copy **JDBC connection string** (thêm `?sslmode=require` nếu cần).

### Bước 3 — Cấu hình biến môi trường và chạy backend

```powershell
$env:DB_JDBC_URL   = "jdbc:postgresql://localhost:5432/konnexus_db"
$env:DB_USERNAME   = "konnexus"
$env:DB_PASSWORD   = "konnexus"
$env:CLOUDINARY_URL = "cloudinary://<api_key>:<api_secret>@<cloud_name>"
$env:GROQ_API_KEY  = "gsk_<your_key>"
$env:QUARKUS_HTTP_HOST = "0.0.0.0"      # cần khi chạy app trên điện thoại thật

.\mvnw.cmd quarkus:dev
```

Backend chạy tại `http://localhost:8080` (Dev UI: `http://localhost:8080/q/dev`).
Lần chạy đầu, Hibernate tự tạo bảng.

### Bước 4 — Tạo tài khoản

Đăng ký qua app hoặc bằng curl:

```powershell
curl.exe -X POST http://localhost:8080/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{\"username\":\"demo\",\"email\":\"demo@konnexus.dev\",\"password\":\"123456\"}'
```

Tài khoản mới ở trạng thái **chưa xác thực**. Link xác thực được **ghi ra log backend**
(chưa cấu hình SMTP), dạng:

```
[EmailVerification] Gửi email xác thực tới demo@konnexus.dev. Mở link: http://localhost:8080/api/auth/verify?token=...
```

Mở link đó bằng trình duyệt (trên máy chạy backend) rồi đăng nhập.
Muốn cấp quyền admin: cập nhật trực tiếp DB
`UPDATE users SET role = 'ADMIN' WHERE email = 'demo@konnexus.dev';`.

### Bước 5 — Chạy ứng dụng Flutter

```powershell
cd frontend
flutter pub get
flutter run --dart-define=KONNEXUS_API_BASE_URL=http://10.0.2.2:8080
```

| Nơi chạy app | URL backend |
|---|---|
| Android Emulator | `http://10.0.2.2:8080` (mặc định) |
| Điện thoại thật cùng Wi-Fi | `http://<IP-LAN-máy-tính>:8080` (xem `ipconfig`) |
| Backend trên máy khác | `http://<IP-máy-backend>:8080` |

---

## 7. Cấu hình

### 7.1 Backend — biến môi trường

`src/main/resources/application.properties` đọc các biến sau (không commit giá trị thật):

| Biến | Bắt buộc | Ý nghĩa |
|---|---|---|
| `DB_JDBC_URL` | ✅ | `jdbc:postgresql://<host>:5432/<db>` |
| `DB_USERNAME`, `DB_PASSWORD` | ✅ | Tài khoản PostgreSQL/Neon |
| `CLOUDINARY_URL` | ✅ khi upload media | `cloudinary://<api_key>:<api_secret>@<cloud_name>` |
| `GROQ_API_KEY` | ✅ khi dùng chatbot | API key Groq (OpenAI-compatible) |
| `JWT_PRIVATE_KEY_LOCATION`, `JWT_PUBLIC_KEY_LOCATION` | ❌ | Mặc định `jwt/privateKey.pem`, `jwt/publicKey.pem` |
| `JWT_ISSUER` | ❌ | Mặc định `konnexus-jwt` |
| `QUARKUS_HTTP_HOST` | ❌ | Đặt `0.0.0.0` để thiết bị khác trong LAN truy cập |

### 7.2 Frontend — địa chỉ backend

Cấu hình tập trung tại `frontend/lib/config/api_config.dart`, ghi đè khi chạy/build:

```powershell
flutter run   --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080
flutter build apk --debug --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080
```

WebSocket tự động suy ra từ URL này (`http` → `ws`, `https` → `wss`).

---

## 8. API chính

| Nhóm | Endpoint tiêu biểu |
|---|---|
| **Auth** | `POST /api/auth/login`, `POST /api/auth/register`, `GET /api/auth/verify?token=` |
| **Upload** | `POST /api/upload` (multipart, field `file`) → `{"url": "..."}` |
| **User** | `GET /api/users`, `PUT /api/users/{id}`, `PUT /api/users/password`, `GET /api/users/search?keyword=`, `PUT /api/users/status?online=` |
| **Post** | `GET/POST /api/v1/posts`, `GET /api/v1/posts/{id}`, `/feed`, `/user/{userId}`, `/trending`, `GET /api/v1/posts/search`, `/tags/{tagName}` |
| **Interaction** | `POST /api/v1/posts/{postId}/reactions`, `GET/POST /api/v1/posts/{postId}/comments`, `POST/GET .../comments/{commentId}/reactions` |
| **Friendship** | `/api/friends/...` — danh sách bạn, lời mời, chấp nhận/từ chối/huỷ, trạng thái quan hệ |
| **Chat REST** | `GET/POST /api/conversations`, `POST /api/conversations/direct/{userId}`, `GET /api/conversations/{id}/members`, `GET/POST /api/messages`, `GET /api/messages/recent/{id}` |
| **Chat WS** | `ws://<host>:8080/chat/{conversation_id}?token=<JWT>` |
| **Notification** | `GET/POST/PUT/DELETE /api/v1/notifications` |
| **Group** | `/api/groups` (tạo/tham gia/duyệt thành viên), `/api/groups/{id}/posts` (bài nhóm + duyệt) |
| **Hashtag** | `GET /api/v1/hashtags/trending`, `GET /api/v1/hashtags/search` |
| **Activity** | `GET /api/activities?from=&to=` — lịch sử hoạt động của chính mình |
| **Admin** | `GET /api/admin/dashboard`, `/api/admin/users/list`, `/api/admin/rooms/list`, `/api/admin/bot/toggle` (`ADMIN`) |

### WebSocket realtime

Client gửi JSON `MessageRequestDTO` với `type`:

| `type` | Hành vi |
|---|---|
| `CHAT` | Lưu DB và broadcast tin nhắn |
| `TYPING` | Broadcast trạng thái đang nhập |
| `READ` | Đánh dấu đã đọc + broadcast |

JWT được truyền qua query `?token=`; `WebSocketAuthFilter` chuyển thành header
`Authorization: Bearer ...` cho handshake. Tin nhắn có `@charles` được chatbot xử lý
bất đồng bộ và broadcast thêm tin nhắn của bot.

---

## 9. Build & kiểm thử

```powershell
# ===== Backend =====
.\mvnw.cmd test                       # unit/integration test
.\mvnw.cmd package -DskipTests        # build jar
java -jar target\quarkus-app\quarkus-run.jar

# ===== Frontend =====
cd frontend
flutter pub get
flutter analyze                       # static analysis
flutter test                          # unit test
dart format --output=none --set-exit-if-changed lib test

# Build APK (debug)
flutter build apk --debug --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080

# Cài lên điện thoại qua ADB
adb install -r -d frontend\build\app\outputs\flutter-apk\app-debug.apk
```

APK nằm tại `frontend/build/app/outputs/flutter-apk/app-debug.apk`.
Sau khi sửa **backend**: rebuild jar + restart (không cần build lại APK).
Sau khi sửa **frontend**: build lại APK hoặc dùng `flutter run` (hot reload).

---

## 10. Xử lý sự cố nhanh

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| App báo lỗi mạng / `Connection refused` | Sai IP backend hoặc backend chưa chạy | Kiểm tra `ipconfig`, chạy BE với `QUARKUS_HTTP_HOST=0.0.0.0`, build lại APK với IP đúng |
| Emulator không kết nối được `localhost` | Emulator không dùng chung localhost với máy tính | Dùng `http://10.0.2.2:8080` |
| `401 Unauthorized` | Token hết hạn / chưa đăng nhập | Đăng nhập lại (app tự `popToRoot` khi gặp 401) |
| Đăng nhập báo tài khoản chưa kích hoạt | Chưa mở link xác thực email | Tìm `[EmailVerification]` trong log backend và mở link |
| `403` ở màn hình admin | Tài khoản không có role `ADMIN` | `UPDATE users SET role='ADMIN' WHERE email='...'` rồi đăng nhập lại |
| Lỗi upload ảnh | Thiếu/sai `CLOUDINARY_URL` hoặc file vượt hạn mức Cloudinary | Kiểm tra biến môi trường; Cloudinary free ~10 MB ảnh / ~100 MB video |
| Chatbot không trả lời | Thiếu `GROQ_API_KEY` hoặc bot bị tắt | Kiểm tra key; bật bot trong trang Admin |
| Gradle báo JDK sai | Flutter chọn JDK > 17 | `flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17..."` |
| Gradle tải NDK rất lâu | Mạng chậm | Xem hướng dẫn tải NDK thủ công trong [SETUP.md](SETUP.md) |

---

## 11. Tài liệu

| Tài liệu | Nội dung |
|---|---|
| [SETUP.md](SETUP.md) | Hướng dẫn cài đặt & chạy app từ A–Z (Windows), kiểm thử API, xử lý lỗi |
| `docs/PROJECT_STRUCTURE.md` | Kiến trúc chi tiết, luồng dữ liệu, quy ước code (file nội bộ) |
| `docs/FE_IMPLEMENTATION_REPORT.md` | Báo cáo triển khai frontend (file nội bộ) |

> Thư mục `docs/` nằm trong `.gitignore` (tài liệu nội bộ của nhóm).

---

## 12. Quy ước đóng góp

- Nhánh: `main` (ổn định) ← `vanna` (phát triển) ← nhánh tính năng `feat/<ten>`.
- Commit theo dạng: `feat(chat): ...`, `fix(post): ...`, `docs: ...`.
- Code style:
  - **Dart**: 2 space, `flutter analyze` phải sạch, comment/chuỗi UI tiếng Việt.
  - **Java**: constructor/field injection, `@Transactional` ở tầng service, DTO đặt trong `dto/`.
- Không commit khóa bí mật thật (`GROQ_API_KEY`, `CLOUDINARY_URL`, mật khẩu DB) — dùng biến môi trường.

---

<div align="center">

**Konnexus** — Đồ án môn học Lập trình Android · Nhóm `konnexus_android_team2`

</div>

