# Hướng dẫn cài đặt & chạy Konnexus

> Tài liệu dành cho thành viên mới (hoặc giảng viên chấm bài) muốn dựng lại toàn bộ
> hệ thống **Konnexus** từ đầu trên Windows. Các lệnh macOS/Linux được ghi chú riêng.
>
> Thời gian dựng lần đầu: **20–40 phút** (chưa tính thời gian Gradle tải NDK/Platform).

## Mục lục

1. [Kiến trúc & cổng dịch vụ](#1-kiến-trúc--cổng-dịch-vụ)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)
3. [Lấy mã nguồn](#3-lấy-mã-nguồn)
4. [Cài đặt PostgreSQL](#4-cài-đặt-postgresql)
5. [Cấu hình backend](#5-cấu-hình-backend)
6. [Chạy backend](#6-chạy-backend)
7. [Tạo tài khoản & kiểm tra API](#7-tạo-tài-khoản--kiểm-tra-api)
8. [Chạy frontend Flutter](#8-chạy-frontend-flutter)
9. [Build APK & cài lên điện thoại](#9-build-apk--cài-lên-điện-thoại)
10. [Kiểm thử & kiểm tra chất lượng code](#10-kiểm-thử--kiểm-tra-chất-lượng-code)
11. [Xử lý sự cố](#11-xử-lý-sự-cố)
12. [Checklist bàn giao](#12-checklist-bàn-giao)

---

## 1. Kiến trúc & cổng dịch vụ

```
Thiết bị Android / Emulator
        │  HTTP REST + WebSocket (JWT)
        ▼
Quarkus Backend  :8080
        ├── PostgreSQL :5432   (dữ liệu)
        ├── Cloudinary HTTPS   (ảnh/video)
        └── Groq HTTPS         (chatbot Charles)
```

| Dịch vụ | Địa chỉ mặc định | Ghi chú |
|---|---|---|
| Backend REST | `http://localhost:8080` | Dev UI: `/q/dev` |
| WebSocket chat | `ws://localhost:8080/chat/{conversationId}?token=<JWT>` | Tự suy ra từ base URL |
| PostgreSQL | `localhost:5432/konnexus_db` | Có thể thay bằng Neon |
| Flutter app | — | Emulator dùng `http://10.0.2.2:8080` |

---

## 2. Yêu cầu hệ thống

| Công cụ | Phiên bản khuyến nghị | Kiểm tra |
|---|---|---|
| **JDK 17** | Temurin/MS OpenJDK 17.0.x | `java -version` |
| **Git** | 2.40+ | `git --version` |
| **PostgreSQL** | 14+ (hoặc Neon) | `psql --version` |
| **Flutter** | 3.24+ / Dart >= 3.4 (kiểm chứng: Flutter 3.47.7, Dart 3.13.5) | `flutter --version` |
| **Android SDK** | Platform 36, Build-Tools 35, NDK 28.2.13676358 | `flutter doctor -v` |
| **ADB** | đi kèm Android SDK platform-tools | `adb version` |

> ⚠️ **Quan trọng**: Gradle của dự án (8.14.3) và backend đều cần **JDK 17**.
> Nếu máy cài JDK 21/25, hãy trỏ Flutter về JDK 17:
>
> ```powershell
> flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
> ```

Kiểm tra nhanh toàn bộ toolchain:

```powershell
flutter doctor
java -version
git --version
```

`flutter doctor` cần báo **OK** (hoặc ít nhất không có lỗi) ở mục *Android toolchain*
và *Android Studio* trước khi build APK.

---

## 3. Lấy mã nguồn

```powershell
git clone https://github.com/NguyenAnhVan335/konnexus_android_team2.git
cd konnexus_android_team2
git checkout vanna
```

Cấu trúc sau khi clone:

```
konnexus_android_team2/
├─ pom.xml          ← backend Quarkus
├─ mvnw.cmd         ← Maven wrapper (không cần cài Maven)
├─ src/             ← mã Java
└─ frontend/        ← app Flutter
```

---

## 4. Cài đặt PostgreSQL

Chọn **một** trong ba cách sau.

### Cách A — PostgreSQL cài trên máy (khuyến nghị cho dev offline)

1. Tải và cài PostgreSQL 16 từ <https://www.postgresql.org/download/windows/>.
2. Mở **SQL Shell (psql)** hoặc PowerShell rồi tạo database + user:

```sql
-- đăng nhập bằng user postgres
CREATE USER konnexus WITH PASSWORD 'konnexus';
CREATE DATABASE konnexus_db OWNER konnexus;
```

Kiểm tra kết nối:

```powershell
psql -U konnexus -d konnexus_db -c "SELECT 1;"
```

### Cách B — Docker (nhanh, không cần cài PostgreSQL)

```powershell
docker run --name konnexus-postgres `
  -e POSTGRES_DB=konnexus_db `
  -e POSTGRES_USER=konnexus `
  -e POSTGRES_PASSWORD=konnexus `
  -p 5432:5432 -d postgres:16
```

### Cách C — Neon (cloud, dùng chung cho cả nhóm)

1. Tạo tài khoản tại <https://neon.tech> → tạo project.
2. Vào **Connection Details**, chọn **JDBC** và copy chuỗi dạng:

```
jdbc:postgresql://ep-xxxx-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
```

3. Tách username/password từ chuỗi `postgresql://user:password@host/db` do Neon cung cấp.

> Hibernate sẽ **tự tạo bảng** ở lần chạy backend đầu tiên
> (`quarkus.hibernate-orm.schema-management.strategy=update`), không cần chạy migration.

---

## 5. Cấu hình backend

Backend đọc cấu hình từ biến môi trường (xem `src/main/resources/application.properties`).

### 5.1 Bảng biến môi trường

| Biến | Bắt buộc | Ví dụ |
|---|---|---|
| `DB_JDBC_URL` | ✅ | `jdbc:postgresql://localhost:5432/konnexus_db` |
| `DB_USERNAME` | ✅ | `konnexus` |
| `DB_PASSWORD` | ✅ | `konnexus` |
| `CLOUDINARY_URL` | ✅ khi upload ảnh/video | `cloudinary://<api_key>:<api_secret>@<cloud_name>` |
| `GROQ_API_KEY` | ✅ khi dùng chatbot | `gsk_xxxxxxxx` |
| `QUARKUS_HTTP_HOST` | ❌ | `0.0.0.0` (để điện thoại thật truy cập) |
| `JWT_PRIVATE_KEY_LOCATION` | ❌ | mặc định `jwt/privateKey.pem` |
| `JWT_PUBLIC_KEY_LOCATION` | ❌ | mặc định `jwt/publicKey.pem` |

### 5.2 Đặt biến môi trường trên PowerShell

```powershell
$env:DB_JDBC_URL    = "jdbc:postgresql://localhost:5432/konnexus_db"
$env:DB_USERNAME    = "konnexus"
$env:DB_PASSWORD    = "konnexus"
$env:CLOUDINARY_URL = "cloudinary://<api_key>:<api_secret>@<cloud_name>"
$env:GROQ_API_KEY   = "gsk_<your_key>"
$env:QUARKUS_HTTP_HOST = "0.0.0.0"
```

> Biến chỉ có hiệu lực trong **cửa sổ PowerShell hiện tại**. Mở terminal mới phải đặt lại.
> Muốn lưu vĩnh viễn (không khuyến khích với key thật):
> `[Environment]::SetEnvironmentVariable("DB_JDBC_URL", "...", "User")`.

Với **CMD**: `set DB_JDBC_URL=...`
<br>Với **bash**: `export DB_JDBC_URL=...`

### 5.3 Lấy Cloudinary & Groq

- **Cloudinary**: <https://console.cloudinary.com> → *Dashboard* → mục **API environment variable**
  có sẵn chuỗi `cloudinary://...`; copy nguyên văn vào `CLOUDINARY_URL`.
  Gói free giới hạn ~10 MB/ảnh, ~100 MB/video.
- **Groq**: <https://console.groq.com/keys> → *Create API Key* → gán vào `GROQ_API_KEY`.
  Model đang dùng: `llama-3.3-70b-versatile` (khai báo trong `application.properties`).

> Backend cần các biến này để khởi động và chạy đầy đủ tính năng. Nếu thiếu
> `CLOUDINARY_URL` hoặc `GROQ_API_KEY`, backend có thể lỗi khi khởi động hoặc khi
> gọi upload/chatbot. Chuỗi `CLOUDINARY_URL` phải đúng định dạng
> `cloudinary://<api_key>:<api_secret>@<cloud_name>`.

### 5.4 JWT key

Repo đã có sẵn cặp khóa **dev** trong `src/main/resources/jwt/`
(`privateKey.pem`, `publicKey.pem`). **Không dùng khóa này cho production.**

Nếu muốn tạo cặp khóa mới:

```powershell
openssl genpkey -algorithm RSA -out privateKey.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in privateKey.pem -out publicKey.pem
```

Đặt 2 file vào `src/main/resources/jwt/` (hoặc trỏ `JWT_PRIVATE_KEY_LOCATION` /
`JWT_PUBLIC_KEY_LOCATION` tới đường dẫn ngoài repo) rồi khởi động lại backend.

---

## 6. Chạy backend

### Cách A — Chế độ dev (hot reload, khuyến nghị khi code BE)

```powershell
.\mvnw.cmd quarkus:dev
```

- Lần đầu Maven tải dependency (có thể mất vài phút).
- Khi thấy dòng `Listening on: http://0.0.0.0:8080`, backend đã sẵn sàng.
- Dev UI: <http://localhost:8080/q/dev>
- Nhấn `s` trong terminal để restart nhanh, `q` để thoát.

### Cách B — Chạy bản jar (giống môi trường thật)

```powershell
.\mvnw.cmd package -DskipTests
java -jar target\quarkus-app\quarkus-run.jar
```

> Mỗi khi sửa code Java phải `package` lại rồi restart. Muốn giữ log để tìm link
> xác thực email:
>
> ```powershell
> java -jar target\quarkus-app\quarkus-run.jar > backend.log 2> backend.err.log
> ```

### macOS / Linux

```bash
./mvnw quarkus:dev
# hoặc
./mvnw package -DskipTests && java -jar target/quarkus-app/quarkus-run.jar
```

---

## 7. Tạo tài khoản & kiểm tra API

### 7.1 Đăng ký

```powershell
curl.exe -X POST http://localhost:8080/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{\"username\":\"demo\",\"email\":\"demo@konnexus.dev\",\"password\":\"123456\"}'
```

### 7.2 Xác thực email

Tài khoản mới có `is_active = false`. Dự án **chưa cấu hình SMTP**, nên
`EmailService` ghi link xác thực ra log backend:

```
[EmailVerification] Gửi email xác thực tới demo@konnexus.dev. Mở link: http://localhost:8080/api/auth/verify?token=<uuid>
```

Tìm link trong terminal đang chạy backend, hoặc trong file log:

```powershell
Select-String -Path backend.log -Pattern "EmailVerification"
```

Mở link bằng trình duyệt trên máy chạy backend → nhận
`Xác thực email thành công. Bạn có thể đăng nhập.`

### 7.3 Đăng nhập & gọi API bảo vệ

```powershell
$login = Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/auth/login `
  -ContentType "application/json" `
  -Body '{"email":"demo@konnexus.dev","password":"123456"}'

$token = $login.token
Invoke-RestMethod -Uri http://localhost:8080/api/users `
  -Headers @{ Authorization = "Bearer $token" }
```

### 7.4 Cấp quyền ADMIN (để dùng màn hình quản trị)

```powershell
psql -U konnexus -d konnexus_db -c "UPDATE users SET role='ADMIN' WHERE email='demo@konnexus.dev';"
```

Sau đó **đăng xuất và đăng nhập lại** để JWT mới chứa role `ADMIN`.

---

## 8. Chạy frontend Flutter

### 8.1 Chuẩn bị

```powershell
cd frontend
flutter pub get
flutter analyze          # phải ra "No issues found!"
```

Nếu `android/local.properties` chưa có, Flutter sẽ tự sinh ở lần chạy đầu tiên
(không cần `flutter create`).

### 8.2 Chạy trên Android Emulator

1. Mở Android Studio → **Device Manager** → khởi động AVD (API 30+).
2. Kiểm tra thiết bị:

```powershell
flutter devices
adb devices
```

3. Chạy app (mặc định đã trỏ `http://10.0.2.2:8080`):

```powershell
flutter run
```

> `10.0.2.2` là địa chỉ đặc biệt của emulator trỏ về `localhost` của máy tính.
> Không dùng `localhost`/`127.0.0.1` từ trong emulator.

### 8.3 Chạy trên điện thoại thật

1. Bật **Nhà phát triển (Developer options)** → **USB debugging**, cắm USB.
2. Chấp nhận hộp thoại *Allow USB debugging* trên điện thoại.
3. Lấy IP LAN của máy tính:

```powershell
ipconfig
# tìm mục "Wireless LAN adapter Wi-Fi" → "IPv4 Address", ví dụ 192.168.1.20
```

4. Cho phép tường lửa mở cổng 8080 (PowerShell **Administrator**):

```powershell
New-NetFirewallRule -DisplayName "Konnexus BE 8080" `
  -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

5. Đảm bảo backend chạy với `QUARKUS_HTTP_HOST=0.0.0.0`, rồi:

```powershell
flutter run --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080
```

> Điện thoại và máy tính phải **cùng một mạng Wi-Fi**. Một số router bật
> *AP isolation* sẽ chặn thiết bị nói chuyện với nhau — khi đó dùng hotspot từ điện thoại
> hoặc chuyển sang emulator.

### 8.4 Đổi địa chỉ backend mà không sửa code

```powershell
flutter run            --dart-define=KONNEXUS_API_BASE_URL=http://10.10.10.5:8080
flutter build apk --debug --dart-define=KONNEXUS_API_BASE_URL=http://10.10.10.5:8080
```

Cấu hình nằm ở `frontend/lib/config/api_config.dart`; WebSocket tự đổi `http→ws`, `https→wss`.

---

## 9. Build APK & cài lên điện thoại

```powershell
cd frontend

flutter build apk --debug --dart-define=KONNEXUS_API_BASE_URL=http://192.168.1.20:8080
```

File APK: `frontend\build\app\outputs\flutter-apk\app-debug.apk`

### Cài qua ADB (khuyến nghị)

```powershell
adb devices        # phải thấy tên thiết bị + "device"
adb install --user 0 -r -d "D:\General\UNI\7\Android\konnexus\konnexus_android_team2\frontend\build\app\outputs\flutter-apk\app-debug.apk"
```

- `--user 0`: cài vào hồ sơ chính (máy OPPO/Xiaomi có nhiều hồ sơ).
- `-r`: cài đè, `-d`: cho phép hạ version.
- Mở app: `adb shell am start --user 0 -n com.konnexus.app/.MainActivity`

### Cài thủ công

Copy file `app-debug.apk` vào điện thoại → mở bằng trình quản lý tệp → **Cài đặt**
→ cho phép *Cài đặt từ nguồn không xác định* nếu được hỏi.

### Khi nào cần build lại?

| Thay đổi | Việc cần làm |
|---|---|
| Code Flutter (`frontend/lib`) | Build lại APK (hoặc `flutter run` để hot reload) |
| Code Java (`src/main/java`) | `.\mvnw.cmd package -DskipTests` + restart backend — **không** cần build lại APK |
| Đổi IP/mạng | Build lại APK với `KONNEXUS_API_BASE_URL` mới |

---

## 10. Kiểm thử & kiểm tra chất lượng code

### Backend

```powershell
.\mvnw.cmd test
```

- Test dùng H2 in-memory (`src/test/resources/application.properties`), không cần PostgreSQL.
- Build jar: `.\mvnw.cmd package -DskipTests`

### Frontend

```powershell
cd frontend
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

- `test/api_client_test.dart`: xử lý 401, gắn header, query, chuẩn hoá lỗi mạng.
- `test/models_test.dart`: parser model, validator, formatter.

### Kiểm tra nhanh backend đang sống

```powershell
curl.exe -i http://localhost:8080/api/auth/login -X POST `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"demo@konnexus.dev\",\"password\":\"123456\"}'
```

Kỳ vọng: `HTTP/1.1 200` + JSON `{"token":"eyJ..."}`.

---

## 11. Xử lý sự cố

### 11.1 Backend

| Lỗi | Nguyên nhân | Cách khắc phục |
|---|---|---|
| `Failed to start datasource ... Connection refused` | PostgreSQL chưa chạy / sai URL | Kiểm tra service PostgreSQL hoặc container Docker; thử `psql -U konnexus -d konnexus_db` |
| `password authentication failed for user "konnexus"` | Sai `DB_USERNAME`/`DB_PASSWORD` | Đặt lại biến môi trường đúng, nhớ mở terminal mới nếu sửa `pg_hba.conf` |
| `FATAL: database "konnexus_db" does not exist` | Chưa tạo DB | Chạy lại phần [4](#4-cài-đặt-postgresql) |
| `Port 8080 already in use` | Có process khác chiếm cổng | `Get-NetTCPConnection -LocalPort 8080` → `Stop-Process -Id <PID>`; hoặc chạy `$env:QUARKUS_HTTP_PORT="8081"` (nhớ đổi URL khi build app) |
| `Unrecognized configuration key ...` | Cảnh báo cấu hình | Chỉ là warning, không chặn chạy |
| Ứng dụng báo `403` khi đăng nhập | Tài khoản chưa xác thực email | Mở link `[EmailVerification]` trong log backend |
| `401` khi gọi API bằng curl | Thiếu header/token hết hạn | Thêm `Authorization: Bearer <token>`, đăng nhập lại |
| Chatbot không trả lời | Thiếu `GROQ_API_KEY` hoặc bot bị tắt | Kiểm tra key; bật bot ở trang quản trị |
| Upload trả lỗi 500/401 | `CLOUDINARY_URL` sai | Copy lại đúng chuỗi `cloudinary://key:secret@cloud_name` |
| Upload file lớn thất bại | Vượt giới hạn Cloudinary free | Nén ảnh/video hoặc nâng gói Cloudinary |

### 11.2 Frontend / Flutter

| Lỗi | Nguyên nhân | Cách khắc phục |
|---|---|---|
| App báo *Không thể kết nối máy chủ* | Sai địa chỉ backend / backend tắt | Kiểm tra backend, `ipconfig`, build lại APK với đúng IP |
| Emulator không gọi được `localhost` | Emulator là máy ảo riêng | Dùng `http://10.0.2.2:8080` |
| Điện thoại thật không kết nối | Tường lửa / khác mạng | Mở cổng 8080, dùng `QUARKUS_HTTP_HOST=0.0.0.0`, cùng Wi-Fi |
| `CLEARTEXT communication not permitted` | Manifest thiếu cờ HTTP | Manifest đã bật `android:usesCleartextTraffic="true"` — kiểm tra lại nếu sửa manifest |
| Gradle báo *Unsupported class file major version* | Flutter dùng JDK > 17 | `flutter config --jdk-dir="<đường dẫn JDK 17>"`, sau đó `flutter clean` |
| Gradle tải NDK rất lâu/treo | Mạng chậm | Tải thủ công (bên dưới) |
| `flutter pub get` lỗi phiên bản | Flutter quá cũ | Nâng Flutter lên 3.24+ |
| APK build xong nhưng cài lỗi `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Khác chữ ký với bản đang cài | Gỡ app cũ: `adb uninstall com.konnexus.app` rồi cài lại |
| Máy OPPO không thấy app sau khi cài | Cài vào hồ sơ phụ | Dùng `adb install --user 0 -r -d <apk>` |

**Tải NDK thủ công** (nếu Gradle treo ở bước NDK):

```powershell
curl.exe -L -C - -o ndk-r28c.zip https://dl.google.com/android/repository/android-ndk-r28c-windows.zip
tar -xf ndk-r28c.zip -C $env:TEMP
Move-Item "$env:TEMP\android-ndk-r28c" "$env:LOCALAPPDATA\Android\Sdk\ndk\28.2.13676358"
```

**Xoá cache build khi lỗi khó hiểu:**

```powershell
cd frontend
flutter clean
flutter pub get
```

### 11.3 Kiểm tra nhanh "hệ thống đã thông chưa"

| Bước | Lệnh | Kết quả mong đợi |
|---|---|---|
| 1. PostgreSQL | `psql -U konnexus -d konnexus_db -c "SELECT 1;"` | `1` |
| 2. Backend | `curl.exe http://localhost:8080/api/users` | JSON lỗi 401 (nghĩa là server đã chạy) |
| 3. Điện thoại → máy tính | mở trình duyệt điện thoại: `http://<IP-LAN>:8080/api/users` | Trả JSON 401 (không phải *site can't be reached*) |
| 4. App | đăng nhập | Vào được bảng tin |

---

## 12. Checklist bàn giao

- [ ] `git checkout vanna` và `git pull` bản mới nhất.
- [ ] JDK 17 là JDK mặc định (`java -version`).
- [ ] PostgreSQL chạy, database `konnexus_db` tồn tại.
- [ ] Đã đặt đủ biến môi trường `DB_*`, `CLOUDINARY_URL`, `GROQ_API_KEY`.
- [ ] `.\mvnw.cmd quarkus:dev` chạy, mở được `http://localhost:8080/q/dev`.
- [ ] Đăng ký + mở link xác thực email trong log + đăng nhập được.
- [ ] `flutter doctor` không có lỗi Android toolchain.
- [ ] `flutter analyze` → *No issues found!*, `flutter test` → pass.
- [ ] `flutter run` trên emulator hiển thị bảng tin.
- [ ] Build APK với IP LAN và cài được lên điện thoại thật.
- [ ] Chat realtime hoạt động giữa 2 tài khoản (WebSocket).
- [ ] Tài khoản `ADMIN` mở được màn hình quản trị.

---

<div align="center">

Cần hỗ trợ thêm? Xem [README.md](README.md) hoặc mở issue trên GitHub.

</div>

