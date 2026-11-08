# Konexus — Flutter client

Ứng dụng mạng xã hội Konexus (Flutter) cho backend Quarkus nằm ở thư mục gốc của repository.

- Ngôn ngữ: Dart / Flutter (Material 3)
- Thư viện ngoài: `http` (gọi REST), `shared_preferences` (lưu phiên đăng nhập và tuỳ chọn giao diện),
  `cached_network_image` (cache avatar/ảnh bài viết)
- Không dùng thư viện state management bên ngoài: dùng `ChangeNotifier` + `ListenableBuilder` + `InheritedWidget` (`AppScope`)

## 1. Yêu cầu môi trường

| Công cụ | Ghi chú |
|---|---|
| Flutter SDK **3.47+** (Dart 3.13) | Đã kiểm chứng với Flutter 3.47.7; `flutter doctor` phải báo OK cho Android toolchain |
| JDK **17** | `flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"` nếu Flutter tự chọn JDK mới hơn (Gradle 8.14.3 không chạy với Java 25) |
| Android SDK Platform 36 + Build-Tools 35 | Gradle tự cài trong lần build đầu |
| NDK **28.2.13676358** + CMake 3.22.1 | Cần cho `sqflite_android`/`jni` (kéo theo bởi `cached_network_image`); xem mục 8 nếu trình tải SDK treo |
| Android Emulator hoặc điện thoại thật | Android 5.0+ |
| Backend Quarkus | chạy tại `http://localhost:8080` trên máy tính |

## 2. Chạy ứng dụng

```bash
cd frontend
flutter pub get
flutter run
```

Nếu thiếu `android/local.properties` (file máy cục bộ), chạy `flutter run` một lần — Flutter tự sinh file này
với đường dẫn SDK. Không cần chạy lại `flutter create` vì thư mục `android/` đã được cấu hình sẵn.

Toolchain Android của dự án: Gradle **8.14.3**, AGP **8.13.0**, Kotlin **2.2.20**, Java **17**. Lần build đầu
tiên Gradle tải thêm Platform 36, Build-Tools 35, NDK 28.2 và CMake (khoảng vài trăm MB).

## 3. Cấu hình địa chỉ backend

Địa chỉ mặc định: `http://10.0.2.2:8080` — đây là địa chỉ đặc biệt của Android Emulator trỏ về `localhost` của máy tính.

Ghi đè khi chạy mà không sửa code:

```bash
# Emulator (mặc định)
flutter run

# Điện thoại thật cùng Wi-Fi với máy tính
flutter run --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080

# Backend chạy trên máy khác trong mạng LAN
flutter run --dart-define=KONNEXUS_API_BASE_URL=http://10.10.10.5:8080
```

Backend phải cho phép HTTP (manifest đã bật `android:usesCleartextTraffic="true"` cho môi trường dev).
Cấu hình nằm ở `lib/config/api_config.dart`; không có URL API nào bị rải trong màn hình.

## 4. Tài khoản đăng nhập

Ứng dụng dùng đúng API của backend:

- `POST /api/auth/register` — tạo tài khoản.
- `POST /api/auth/login` — nhận JWT, id người dùng đọc từ claim `sub` của token.

Sau khi đăng nhập, `ApiClient` tự gắn các header:

| Header | Dùng cho |
|---|---|
| `Authorization: Bearer <token>` | `/api/users` (yêu cầu `@Authenticated`) |
| `X-User-Id` | Post API (`/api/v1/posts`) |
| `X-Test-User-Id` | Friendship API (`/api/friends`) — chỉ backend dev/test chấp nhận |

## 5. Chức năng

| Màn hình | Trạng thái |
|---|---|
| Đăng nhập / Đăng ký | Kết nối thật |
| Trang chủ (bảng tin, phân trang, kéo làm mới) | Kết nối thật |
| Tạo / sửa / xoá mềm bài viết, chọn quyền riêng tư, media bằng URL | Kết nối thật |
| Cảm xúc (LIKE/LOVE/HAHA/WOW/SAD/ANGRY) | Kết nối thật |
| Bình luận | Kết nối thật (backend chưa có tác giả bình luận) |
| Khám phá — bài viết nổi bật theo 7/30/365 ngày | Kết nối thật |
| Bạn bè: danh sách, lời mời nhận/gửi, chấp nhận/từ chối/huỷ, bỏ kết bạn, nhắn tin | Kết nối thật (chỉ khi backend dev/test) |
| Trang cá nhân (của mình và người khác), thêm bạn, chia sẻ | Kết nối thật |
| Chỉnh sửa hồ sơ (tên, email, mật khẩu, avatar URL, giới tính, sinh nhật, địa chỉ) | Lõi kết nối thật; giới tính/sinh nhật/địa chỉ lưu cục bộ |
| Tìm kiếm người dùng (lọc online/bạn bè, lưu từ khoá) | Kết nối thật, lọc phía client |
| Tin nhắn + trò chuyện | **Dữ liệu mẫu** (backend chưa có API chat) |
| Thông báo | **Dữ liệu mẫu** (backend chưa có API thông báo) |
| Cài đặt: sáng/tối, màu theme, đăng xuất | Hoạt động cục bộ |

Phần dùng dữ liệu mẫu được ghi rõ ngay trên giao diện (`MockDataBanner`) và tách khỏi UI qua
`ChatService` / `NotificationService` (implementation `Mock*`), nên chỉ cần thay service khi backend
bổ sung API.

### Phiên hết hạn (HTTP 401)

Mọi request cần xác thực trả `401` đều được xử lý tập trung: `ApiClient` gọi `onUnauthorized` →
`SessionController.handleUnauthorized()` xoá phiên, `AppNavigator.popToRoot()` đóng các màn hình đang mở và
`LoginPage` hiện thông báo *"Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."*.

- Endpoint công khai (`/api/auth/login`, `/api/auth/register`) gọi với `authenticated: false` nên nhập sai
  mật khẩu **không** bị coi là phiên hết hạn.
- Nhiều request 401 đồng thời chỉ đăng xuất một lần.
- `AppChangeNotifier` bỏ qua `notifyListeners()` sau `dispose`, nên response về muộn không gây lỗi
  "used after being disposed".

Avatar và ảnh bài viết dùng `CachedNetworkImage` (cache bộ nhớ + đĩa, có placeholder/ảnh lỗi).

## 6. Cấu trúc

```text
lib/
├── main.dart, app.dart          # khởi tạo, MaterialApp, AppGate theo phiên đăng nhập
├── config/                      # địa chỉ backend, giới hạn nghiệp vụ
├── core/
│   ├── api/                     # ApiClient + ApiException (một nơi duy nhất gọi HTTP)
│   ├── auth/                    # đọc claim sub từ JWT
│   ├── di/                      # AppServices + AppScope (DI thủ công)
│   └── storage/                 # SharedPreferences (token, theme, từ khoá đã lưu)
├── models/                      # model khớp payload backend (snake_case)
├── services/                    # một service cho mỗi nhóm API + mock service
├── state/                       # ChangeNotifier: session, feed, detail, friends, profile, search...
├── navigation/                  # AppRoutes, AppRouter, tham số điều hướng
├── theme/                       # màu, khoảng cách, ThemeData sáng/tối
├── utils/                       # JSON an toàn, formatter, validator
├── widgets/                     # component tái sử dụng (app bar, post card, avatar, state views...)
├── features/                    # màn hình theo nghiệp vụ
│   ├── auth/ home/ explore/ messages/ friends/ profile/ search/ notifications/ post/ shell/
└── data/mock/                   # dữ liệu mẫu cho chat/thông báo
```

## 7. Giới hạn đã biết

1. **Chưa có `GET /api/users/me`**: hồ sơ hiện tại lấy bằng `GET /api/users` rồi tìm theo id trong JWT.
   Endpoint này trả entity `User` đầy đủ (kể cả trường `password`), nên backend nên bổ sung DTO an toàn.
2. **`PUT /api/users/{id}` ghi đè mật khẩu vô điều kiện**: form chỉnh sửa bắt buộc nhập mật khẩu để tránh
   xoá mật khẩu hiện tại. Nên chuyển sang cập nhật từng phần (PATCH) và không nhận mật khẩu ở đây.
3. **Friendship API chỉ chạy ở dev/test** (header `X-Test-User-Id`). Khi backend chạy production, các màn
   hình Bạn bè/Trang cá nhân sẽ báo lỗi 403 kèm ghi chú.
4. **Chưa có API chat/thông báo/tìm kiếm/upload ảnh**: Tin nhắn & Thông báo dùng dữ liệu mẫu; tìm kiếm lọc
   phía client trên `GET /api/users`; media bài viết nhập bằng URL.
5. **Bình luận chưa có tác giả** (`post_comments` thiếu cột `author_id`) nên hiển thị nhãn "Người dùng".
6. Backend chưa cập nhật `is_online` nên "Số người online" luôn là 0.

## 8. Kiểm tra

Đã chạy thật với Flutter 3.47.7 / Dart 3.13.5 / JDK 17 (ngày 19/10/2026):

```bash
cd frontend
flutter pub get
flutter analyze                                  # No issues found!
flutter test                                     # 14/14 test pass
dart format --output=none --set-exit-if-changed lib test   # 0 file cần đổi
flutter build apk --debug                        # app-debug.apk (149,4 MB)
```

- `test/models_test.dart`: parser `PostModel`/`PageData`, validator, formatter (8 test).
- `test/api_client_test.dart`: xử lý 401 (`onUnauthorized`), bỏ qua endpoint công khai, gắn header, query,
  chuẩn hoá lỗi mạng (6 test).

Lưu ý khi build trên máy mới:

```bash
# Flutter đang dùng JDK quá mới (Java 25) → chọn JDK 17:
flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
```

Nếu Gradle báo đang tải NDK rất lâu/treo, tải thủ công rồi giải nén vào SDK:

```powershell
curl.exe -L -C - -o ndk-r28c.zip https://dl.google.com/android/repository/android-ndk-r28c-windows.zip
tar -xf ndk-r28c.zip -C $env:TEMP
Move-Item "$env:TEMP\android-ndk-r28c" "$env:LOCALAPPDATA\Android\Sdk\ndk\28.2.13676358"
```

Chưa chạy được trên emulator/điện thoại vì máy kiểm chứng không có AVD/thiết bị Android (`flutter emulators`
trống). Xem mục G trong `docs/FE_IMPLEMENTATION_REPORT.md` để biết chi tiết các kiểm tra và lỗi đã sửa.
