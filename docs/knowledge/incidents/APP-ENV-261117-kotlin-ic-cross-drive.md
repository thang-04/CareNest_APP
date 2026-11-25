---
id: APP-ENV-261117-kotlin-ic-cross-drive
type: env
roles: [all]
screens: [build-android]
platforms: [android]
be_refs: []
status: fixed
date: 2026-11-17
keywords: [android, apk, gradle, kotlin, incremental, "Could not close incremental caches", "Daemon compilation failed", windows, pub cache, ổ đĩa, url_launcher_android, image_picker_android]
similar_to: []
---

# APP-ENV-261117-kotlin-ic-cross-drive — build APK lỗi ở plugin Kotlin: "Could not close incremental caches"

## Symptom
`flutter build apk --debug` lỗi ở các plugin có mã Kotlin, dòng đầu chỉ ghi `e: Daemon compilation failed`:
```text
Execution failed for task ':image_picker_android:compileDebugKotlin'.
> java.lang.Exception: Could not close incremental caches in D:\project_capstone\project\web\carenest_app\build\image_picker_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
```
Cùng lỗi ở `:url_launcher_android:compileDebugKotlin`.

## Điều kiện tái hiện
Windows 11, Flutter 3.47.6, AGP 9.0.1, Kotlin Gradle plugin 2.3.20, build debug. Project ở ổ D: (`D:\project_capstone\...`), Pub cache mặc định ở ổ C: (`C:\Users\<user>\AppData\Local\Pub\Cache`). Chỉ plugin có file `.kt` lỗi (`url_launcher_android` 6.3.x, `image_picker_android` 0.8.13+25); plugin chỉ Java (`flutter_secure_storage`, `flutter_appauth`) build được. Lỗi có từ khi App có plugin Kotlin đầu tiên (`url_launcher`, merge G94-385 ngày 17/11); APK ngày 15/11 còn build được.

## Attempts — đã thử (cập nhật mỗi phiên điều tra, để phiên sau không lặp lại)
| # | Cách thử | Kết quả | Vì sao không đúng / bài học |
| --- | --- | --- | --- |
| 1 | Chạy lại `flutter build apk --debug` | Lỗi y hệt, thêm `url_launcher_android` | Không phải lỗi thoáng qua; không do riêng `image_picker` |
| 2 | `android\gradlew.bat assembleDebug "-Pkotlin.incremental=false"` | BUILD SUCCESSFUL | Xác nhận lỗi nằm ở incremental compilation của Kotlin |
| 3 | Thêm `kotlin.incremental=false` vào `android/gradle.properties`, xoá `build\image_picker_android` và `build\url_launcher_android`, chạy lại `flutter build apk --debug` | `√ Built build\app\outputs\flutter-apk\app-debug.apk` | Fix chọn |

## Root cause
Thiết bị–môi trường. Kotlin incremental compilation ghi đường dẫn file nguồn tương đối so với thư mục build. Nguồn plugin nằm trong Pub cache ở ổ C:, thư mục build ở ổ D:, nên không tính được đường dẫn tương đối giữa hai ổ ("this and base files have different roots"); daemon gói lỗi này thành "Could not close incremental caches". Bằng chứng: tắt incremental thì build qua (attempt 2); plugin chỉ Java không bị. Nguồn ngoài: [startdebugging.net — Fix: e: Daemon compilation failed](https://startdebugging.net/2026/09/fix-daemon-compilation-failed-null-in-a-flutter-android-gradle-build/) (nhắc KT-63983).

## Fix
`android/gradle.properties`: `kotlin.incremental=false` (user chọn 17/11, áp dụng cả nhóm). App chỉ có `MainActivity.kt` nhỏ, nguồn plugin không đổi giữa các lần build ⇒ gần như không chậm hơn. Cách khác cho từng máy: để Pub cache cùng ổ với project (biến `PUB_CACHE`) rồi `flutter clean` + `flutter pub get`.

## Regression test
Kiểm tra tay: xoá `build\image_picker_android` và `build\url_launcher_android` (dừng Gradle trước: `android\gradlew.bat --stop`; xoá bằng `rmdir /s /q` vì PowerShell không xoá được file có `$` trong tên), chạy `flutter build apk --debug` ⇒ `√ Built build\app\outputs\flutter-apk\app-debug.apk`. Chưa có test tự động (cần Gradle và hai ổ đĩa).

## Ảnh hưởng
Mọi plugin Android viết Kotlin, kể cả plugin thêm sau này. CI chạy Linux không bị (một gốc thư mục).

## Lesson
Trên Windows, project và Pub cache khác ổ đĩa làm Kotlin incremental compilation hỏng; lỗi hiện thành "Could not close incremental caches" ở plugin, không phải lỗi của plugin.
