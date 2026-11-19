# Konexus — Flutter client

Ứng dụng Android của **Konnexus** (Flutter, Material 3), kết nối backend Quarkus nằm ở
thư mục gốc repository.

> 📖 Tổng quan dự án: [../README.md](../README.md) · Hướng dẫn cài đặt đầy đủ:
> [../SETUP.md](../SETUP.md)

## 1. Công nghệ & kiến trúc

| Hạng mục | Lựa chọn |
|---|---|
| Framework | Flutter (Material 3), Dart >= 3.4 |
| Điều hướng | `Navigator` + named routes (`AppRouter.onGenerateRoute`) |
| Quản lý state | `ChangeNotifier` + `ListenableBuilder` + `InheritedWidget` (`AppScope`) — **không** dùng Bloc/Riverpod/Provider |
| Gọi API | `package:http` (`ApiClient` duy nhất, tự gắn JWT, xử lý 401 tập trung) |
| Realtime | WebSocket (`chat_socket_io.dart`, stub cho web) |
| Lưu trữ cục bộ | `shared_preferences` (token, user cache, theme, từ khoá tìm kiếm) |
| Ảnh | `cached_network_image` |
| Khác | `share_plus`, `image_picker`, `url_launcher` |

Luồng khởi động:

```
main() → AppServices.bootstrap()   (PreferencesStore, SessionController, ApiClient, services)
       → AppScope (InheritedWidget)
       → MaterialApp(onGenerateRoute: AppRouter)
       → AppGate: Splash / LoginPage / MainShell (5 tab)
```

## 2. Yêu cầu môi trường

| Công cụ | Ghi chú |
|---|---|
| Flutter **3.24+** (Dart >= 3.4) | Đã kiểm chứng với Flutter 3.47.7 / Dart 3.13.5 |
| JDK **17** | Gradle 8.14.3 không chạy với JDK 21/25 — dùng `flutter config --jdk-dir=...` |
| Android SDK Platform 36, Build-Tools 35, NDK 28.2.13676358 | Gradle tự tải lần build đầu |
| Backend Quarkus | chạy tại `http://localhost:8080` |

## 3. Chạy ứng dụng

```powershell
cd frontend
flutter pub get
flutter analyze
flutter run                                        # emulator, mặc định http://10.0.2.2:8080
```

Điện thoại thật (cùng Wi-Fi, backend chạy `QUARKUS_HTTP_HOST=0.0.0.0`):

```powershell
flutter run --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080
```

Địa chỉ backend được cấu hình **tập trung** tại `lib/config/api_config.dart`:

| Hằng số | Giá trị |
|---|---|
| `baseUrl` | `String.fromEnvironment('KONNEXUS_API_BASE_URL', defaultValue: 'http://10.0.2.2:8080')` |
| `wsBaseUrl` | tự đổi `http→ws`, `https→wss` |
| `requestTimeout` | 20 giây |
| `uploadTimeout` | 300 giây |
| `pageSize` | 10 |

## 4. Cấu trúc `lib/`

```
lib/
├─ main.dart, app.dart         # bootstrap, MaterialApp, AppGate
├─ config/api_config.dart      # địa chỉ backend, timeout, giới hạn nghiệp vụ
├─ core/
│  ├─ api/                     # ApiClient + ApiException
│  ├─ auth/jwt_utils.dart      # đọc claim `sub` từ JWT
│  ├─ di/                      # AppServices + AppScope (service locator)
│  └─ storage/                 # PreferencesStore
├─ models/                     # User, Post, Comment, Chat, Notification, Admin, Activity...
├─ services/                   # auth, user, post, interaction, friendship, chat, notification,
│                              # file upload, activity, admin, chat_socket (IO/stub)
├─ state/                      # ChangeNotifier: session, feed, post detail, friends, messages,
│                              # notifications, profile, settings, admin...
├─ navigation/                 # AppRoutes, AppRouter, AppArguments
├─ features/
│  ├─ auth/ shell/ home/ explore/ messages/ notifications/
│  ├─ post/ profile/ friends/ search/ admin/
├─ widgets/                    # PostCard, KonexusAppBar, AvatarView, StateViews, AppLogo...
├─ theme/                      # AppColors, AppSpacing, AppTheme
└─ utils/                      # validators, formatters, json_utils, share_utils
```

Quy ước: service chỉ ném `ApiException`; màn hình bắt lỗi và hiển thị `error.userMessage`;
luôn kiểm tra `mounted` sau `await`; widget dùng chung đặt trong `widgets/`.

## 5. Kiểm thử & build

```powershell
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test

flutter build apk --debug --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080
# APK: build/app/outputs/flutter-apk/app-debug.apk
```

Test hiện có:

- `test/api_client_test.dart` — gắn header, 401 → `onUnauthorized`, query, chuẩn hoá lỗi mạng.
- `test/models_test.dart` — parser model, validator, formatter.

## 6. Lưu ý

- Backend bật `android:usesCleartextTraffic="true"` cho HTTP dev; production nên dùng HTTPS.
- Đăng ký tài khoản cần xác thực email: link nằm trong log backend (`[EmailVerification]`).
- Tài khoản `ADMIN` mới thấy tab/menu quản trị (xem `SETUP.md` mục 7.4).
- Xem thêm xử lý lỗi Gradle/NDK/JDK trong [../SETUP.md](../SETUP.md) mục 11.
