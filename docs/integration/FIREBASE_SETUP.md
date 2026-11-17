# Cấu hình Firebase để kiểm thử Android

Không cần cài Android Studio để làm các bước Firebase. Tạo dự án và khóa là thao tác của chủ tài khoản; không gửi nội dung khóa hoặc token vào chat, Git hay log.

1. Mở [Firebase console](https://console.firebase.google.com/), tạo hoặc chọn dự án của trường và đăng ký ứng dụng Android với application ID hiện tại **`com.example.carenest_app`**. Đây là ID mẫu đang có trong source; nếu đổi ID sau này phải đăng ký app tương ứng và tải cấu hình mới.
2. Tải `google-services.json` theo [hướng dẫn Firebase](https://firebase.google.com/docs/android/setup) và đặt tại `CareNest_APP/android/app/google-services.json`; file này đã được thêm vào `.gitignore`.
3. Bật Cloud Messaging / Firebase Cloud Messaging API trong dự án Google Cloud tương ứng. Trong phần tài khoản dịch vụ của dự án, người quản trị tạo khóa JSON có quyền gửi FCM phù hợp, lưu **ngoài Git** trong thư mục chỉ tài khoản chạy backend được đọc.
4. Với Compose, đặt `CARENEST_PUSH_FCM_HOST_DIR` bằng thư mục chứa khóa và `CARENEST_PUSH_FCM_CREDENTIALS_FILE=/run/carenest/fcm/<tên-file>.json`; mount chỉ đọc đã được khai báo. `CARENEST_PUSH_WORKER_ENABLED=true` bật worker mới. Không đặt nội dung khóa vào biến môi trường, image hoặc file mẫu.
5. Cấu hình App bằng `--dart-define=CARENEST_API_BASE_URL=https://<host>/api` và `--dart-define=CARENEST_OIDC_ISSUER=https://<host>/realms/carenest`. Keycloak phải có public client `carenest-mobile`, PKCE S256 và redirect `carenest://oauth/callback` đúng hợp đồng BE.
6. Build APK cần Android SDK và chấp nhận giấy phép SDK; chỉ dùng command-line tools nếu không muốn Android Studio. Cần điện thoại Android có Google Play services, quyền thông báo và mạng, cùng tài khoản thử. Test foreground/nền/đóng thường/khóa và kiểm tra tin toàn văn, tệp, đổi tài khoản, không dùng dữ liệu trẻ thật.

Không coi log gateway hay FCM accepted là bằng chứng điện thoại đã nhận. Chưa triển khai môi trường hoặc gửi thông báo thật khi chưa được chỉ đạo.
