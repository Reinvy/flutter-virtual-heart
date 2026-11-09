# PLATFORM_SETUP — Konfigurasi per Platform

## 1. Android (didukung)

| Item | Nilai | Lokasi |
| --- | --- | --- |
| AGP | 9.1.0 | `android/settings.gradle.kts` |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Kotlin plugin | 2.4.0 | `android/settings.gradle.kts` |
| compileSdk | 37 | `android/app/build.gradle.kts` |
| minSdk / targetSdk | 30 / 36 (`flutter.targetSdkVersion`) | idem |
| NDK | `flutter.ndkVersion` | idem |
| ABI | `arm64-v8a` saja | idem |
| JDK | 17+ | `jvmTarget = JVM_17` |
| Flags Gradle | `android.useAndroidX=true`, `android.newDsl=false`, `android.builtInKotlin=false` | `android/gradle.properties` |

Catatan:

- `android.newDsl=false` dipertahankan karena `org.jetbrains.kotlin.android` (dipakai juga oleh
  plugin pihak ketiga) belum kompatibel dengan new DSL AGP 9. AGP dipin **9.1.0**: 9.1.1
  mengubah accessor DSL lama menjadi error kompilasi, sedangkan 9.0.1 ditolak `androidx.core 1.19.0`
  (lihat `DEPENDENCIES.md` §5). AGP 9.1.0 memberi peringatan "tested up to compileSdk 36.1"; build debug
  dengan compileSdk 37 tetap lulus.
- `compileSdk = 37` wajib untuk `flutter_local_notifications 23`.
- `android/build.gradle.kts` memaksa `compileSdk = 37` untuk seluruh subproject library:
  sebagian plugin (`flutter_pcm_sound`) masih mengunci `compileSdkVersion 33`, sementara
  dependency androidx-nya menuntut 34+ sehingga `checkAarMetadata` gagal.
- Permission di `AndroidManifest.xml`: `INTERNET`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`,
  `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, Bluetooth
  (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`), `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_DATA_SYNC`. WorkManager `SystemForegroundService` di-override ke
  `dataSync` untuk unduhan model besar.
- Penyimpanan model: direktori aplikasi milik `flutter_edge_ai` (bukan `assets/`), diunduh dari
  HuggingFace atau di-upload pengguna.
- Build: `make apk` atau `fvm flutter build apk --debug`.
- Application ID masih `com.example.edge_chat` dan release memakai signing debug — lihat
  `KNOWN_ISSUES.md`.

## 2. iOS (didukung, belum diverifikasi di Linux)

- Deployment target **16.0** pada tiga konfigurasi Runner (`project.pbxproj`).
- `ios/Podfile`: `platform :ios, '16.0'`, `use_frameworks! :linkage => :static`.
- `ios/Runner/Runner.entitlements`: `extended-virtual-addressing`, `increased-memory-limit`,
  `increased-debugging-memory-limit`; dirujuk lewat `CODE_SIGN_ENTITLEMENTS` di tiga konfigurasi.
- `Info.plist`: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` sudah ada.
- Plugin dapat memakai Swift Package Manager (Flutter) atau CocoaPods; keduanya butuh Xcode.
- **Belum diverifikasi**: tidak ada Xcode/CocoaPods di lingkungan build saat ini. Jangan
  mengklaim `flutter build ios` lulus.

## 3. macOS (eksperimental, belum diverifikasi)

- `MACOSX_DEPLOYMENT_TARGET = 14.0` (tiga konfigurasi).
- Entitlements (`DebugProfile.entitlements`, `Release.entitlements`): sandbox,
  `network.client`, `device.audio-input` (+ `network.server`/`allow-jit` di debug).
- `Info.plist`: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`.
- Belum ada Podfile (Flutter mengelola SPM/CocoaPods); bila build meminta, pakai
  `platform :osx, '14.0'`.

## 4. Linux / Windows (eksperimental)

- Tidak ada konfigurasi khusus di repo; `flutter run -d linux` / `-d windows` belum diuji.
- Rekaman audio di Linux bergantung pada `record_linux` (butuh `parecord`/`ffmpeg` sesuai
  dokumentasi paket).
- Notifikasi desktop memakai implementasi plugin yang berbeda; belum diverifikasi.

## 5. Web (tidak didukung)

- `web/` tetap ada (title/metadata VirtualHeart) tetapi aplikasi memakai `dart:io` di
  settings/ekspor/model/STT/notifikasi, dan `flutter_edge_ai_speech` tidak mendukung web
  secara penuh.
- `web/index.html` sengaja menyatakan web bukan platform yang didukung.

## 6. Kebutuhan jaringan & penyimpanan

- Unduhan model: 135 MB – 1.7 GB per model (default 1.6 GB). Butuh internet sekali; setelah itu
  inferensi berjalan offline.
- Font Google Fonts diambil saat runtime (cache OS/browser); tanpa jaringan font jatuh ke
  fallback.
- Token HuggingFace opsional, hanya untuk model *gated* (Gemma 3 1B). Disimpan di
  `SharedPreferences`.
