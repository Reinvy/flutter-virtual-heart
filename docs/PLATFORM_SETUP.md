# PLATFORM_SETUP — Konfigurasi per Platform

## 1. Android (didukung)

| Item | Nilai | Lokasi |
| --- | --- | --- |
| AGP | 9.3.1 | `android/settings.gradle.kts` |
| Gradle | 9.5.0 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Kotlin plugin | 2.4.20 | `android/settings.gradle.kts` (dideklarasikan, di-apply Flutter Gradle Plugin) |
| compileSdk | 37 | `android/app/build.gradle.kts` |
| minSdk / targetSdk | 30 / 36 (`flutter.targetSdkVersion`) | idem |
| NDK | `flutter.ndkVersion` | idem |
| ABI | `arm64-v8a` saja | idem |
| JDK | 17+ | `jvmTarget = JVM_17` |
| Flags Gradle | `android.useAndroidX=true`, `android.newDsl=false`, `android.builtInKotlin=false` | `android/gradle.properties` |

Catatan:

- Toolchain Android mengikuti template Flutter 3.50.1: AGP **9.3.1**, Gradle **9.5.0**, Kotlin
  plugin **2.4.20**. `android.newDsl=false` dan `android.builtInKotlin=false` dipertahankan karena
  plugin pihak ketiga masih memakai DSL lama; `android/app/build.gradle.kts` tidak lagi meng-apply
  `kotlin-android` (Flutter Gradle Plugin yang meng-apply KGP ke modul app).
- `compileSdk = 37` wajib untuk `flutter_local_notifications 23`.
- `android/build.gradle.kts` memaksa `compileSdk = 37` untuk seluruh subproject library:
  sebagian plugin (`flutter_pcm_sound`) masih mengunci `compileSdkVersion 33`, sementara
  dependency androidx-nya menuntut 34+ sehingga `checkAarMetadata` gagal.
- Permission di `AndroidManifest.xml`: `INTERNET`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`,
  `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, Bluetooth
  (`BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`), `FOREGROUND_SERVICE`,
  `FOREGROUND_SERVICE_DATA_SYNC`. WorkManager `SystemForegroundService` di-override ke
  `dataSync` untuk unduhan model besar.
- `AndroidManifest.xml` menetapkan `android:allowBackup="false"` untuk keamanan
  `flutter_secure_storage` (mencegah kegagalan dekripsi Keystore setelah Android Auto Backup).
- Pemutaran audio Cloud TTS memakai `audioplayers` (`DeviceFileSource` dari file temp) dengan
  cleanup otomatis setelah selesai atau dibatalkan.
- Penyimpanan model lokal: direktori aplikasi milik `flutter_edge_ai` (bukan `assets/`), diunduh dari
  HuggingFace atau di-upload pengguna.
- Build: `make apk` (atau `fvm flutter build apk --debug`).
- Application ID masih `com.example.edge_chat` dan release memakai signing debug — lihat
  `KNOWN_ISSUES.md`.

## 2. iOS (didukung, belum diverifikasi di Linux)

- Deployment target **16.0** pada tiga konfigurasi Runner (`project.pbxproj`).
- `ios/Podfile`: `platform :ios, '16.0'`, `use_frameworks! :linkage => :static`.
- `ios/Runner/Runner.entitlements`: `extended-virtual-addressing`, `increased-memory-limit`,
  `increased-debugging-memory-limit`; dirujuk lewat `CODE_SIGN_ENTITLEMENTS` di tiga konfigurasi.
- `Info.plist`: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` sudah ada.
- `flutter_secure_storage` memakai Keychain iOS dengan `KeychainAccessibility.first_unlock_this_device`.
- Plugin dapat memakai Swift Package Manager (Flutter) atau CocoaPods; keduanya butuh Xcode.
- **Belum diverifikasi**: tidak ada Xcode/CocoaPods di lingkungan build saat ini. Jangan
  mengklaim `flutter build ios` lulus.

## 3. macOS (eksperimental, belum diverifikasi)

- `MACOSX_DEPLOYMENT_TARGET = 14.0` (tiga konfigurasi).
- Entitlements (`DebugProfile.entitlements`, `Release.entitlements`): sandbox,
  `network.client`, `device.audio-input` (+ `network.server`/`allow-jit` di debug).
- `flutter_secure_storage` memakai `MacOsOptions(usesDataProtectionKeychain: false)` agar build
  lokal tanpa provisioning profile berbayar tidak gagal dengan kode Keychain `-34018`.
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

- **Mode Lokal**: unduhan model 135 MB – 1.7 GB per model (default 1.6 GB); butuh internet sekali,
  setelah itu inferensi berjalan offline.
- **Mode Cloud BYOK & Cloud Speech (opsional)**: butuh koneksi internet ke endpoint provider yang
  dikonfigurasi pengguna (atau LAN untuk Ollama/LM Studio lokal), tanpa perlu mengunduh bobot model
  gigabyte ke perangkat.
- Font Google Fonts diambil saat runtime (cache OS/browser); tanpa jaringan font jatuh ke
  fallback.
- Token HuggingFace opsional untuk model lokal *gated* (Gemma 3 1B) disimpan di `SharedPreferences`;
  seluruh API key Cloud BYOK disimpan terenkripsi di `flutter_secure_storage`.
