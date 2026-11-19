import 'dart:async';

import '../api/api_client.dart';
import '../storage/preferences_store.dart';
import '../../navigation/app_navigator.dart';
import '../../services/admin_service.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/friendship_service.dart';
import '../../services/interaction_service.dart';
import '../../services/notification_service.dart';
import '../../services/post_service.dart';
import '../../services/user_service.dart';
import '../../state/notifications_controller.dart';
import '../../state/session_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/users_directory.dart';

/// "Service locator" thủ công của ứng dụng: tạo một lần ở `main()` và chia sẻ
/// qua `AppScope`, tránh phụ thuộc thư viện DI bên ngoài.
class AppServices {
  AppServices._({
    required this.apiClient,
    required this.session,
    required this.authService,
    required this.userService,
    required this.postService,
    required this.friendshipService,
    required this.interactionService,
    required this.chatService,
    required this.notificationService,
    required this.fileUploadService,
    required this.adminService,
    required this.activityService,
    required this.notifications,
    required this.settings,
    required this.usersDirectory,
    required this.preferencesStore,
  });

  final ApiClient apiClient;
  final SessionController session;
  final AuthService authService;
  final UserService userService;
  final PostService postService;
  final FriendshipService friendshipService;
  final InteractionService interactionService;

  /// Chat & notification gọi REST (backend đã có API); file upload dùng multipart.
  final ChatService chatService;
  final NotificationService notificationService;
  final FileUploadService fileUploadService;
  final AdminService adminService;
  final ActivityService activityService;

  /// Controller dùng chung cho màn Thông báo và badge trên chuông app bar.
  final NotificationsController notifications;

  final SettingsController settings;
  final UsersDirectory usersDirectory;
  final PreferencesStore preferencesStore;

  static Future<AppServices> bootstrap() async {
    final PreferencesStore store = await PreferencesStore.create();
    final SessionController session = SessionController(store: store);
    final ApiClient api = ApiClient(headersProvider: () => session.authHeaders);
    final AuthService authService = AuthService(api);
    final UserService userService = UserService(api);
    final UsersDirectory usersDirectory = UsersDirectory(userService);
    final SettingsController settings = SettingsController(store)..load();
    final NotificationService notificationService = ApiNotificationService(api);
    final NotificationsController notifications =
        NotificationsController(notificationService);

    session.attach(
      authService: authService,
      userService: userService,
      onSessionCleared: () {
        usersDirectory.clear();
        notifications.clear();
      },
    );

    // Xử lý 401 tập trung: token hết hạn ở bất kỳ endpoint nào cũng đưa người
    // dùng về màn hình đăng nhập kèm thông báo, thay vì mỗi màn hình tự xử lý.
    api.onUnauthorized = () {
      unawaited(session.handleUnauthorized());
      AppNavigator.popToRoot();
    };

    await session.restore();

    return AppServices._(
      apiClient: api,
      session: session,
      authService: authService,
      userService: userService,
      postService: PostService(api),
      friendshipService: FriendshipService(api),
      interactionService: InteractionService(api),
      chatService: ApiChatService(api, session),
      notificationService: notificationService,
      fileUploadService: FileUploadService(api),
      adminService: AdminService(api),
      activityService: ActivityService(api),
      notifications: notifications,
      settings: settings,
      usersDirectory: usersDirectory,
      preferencesStore: store,
    );
  }

  void dispose() {
    apiClient.dispose();
    usersDirectory.dispose();
    notifications.dispose();
    settings.dispose();
    session.dispose();
  }
}
