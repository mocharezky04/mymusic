# MyMusic

Aplikasi pemutar musik pribadi: cari, streaming, dan simpan lagu untuk diputar offline, tanpa akun dan tanpa iklan. Dipercaya oleh YouTube Music/YouTube untuk cari lagu, streaming lewat backend sendiri yang menjalankan yt-dlp, dan yang penting, semua kontrol ada di tangan kita sendiri.

Kode tersusun jadi dua bagian: `app/` untuk kliennya (Flutter, jalan di Android dan web) dan `backend/` untuk API-nya (FastAPI + yt-dlp + optional Redis).

## Fitur

- Pencarian lagu dari beberapa sumber (YouTube, YouTube Music, SoundCloud, Spotify). Yang bukan lagu (Spotify yang cuma metadata, misalnya) ditandai supaya tidak bikin kacau antrian.
- Pemutaran background di Android: notifikasi dengan kontrol play/pause/next/prev, tetap jalan saat layar mati, kontrol di lock screen, MediaSession.
- Akun YouTube multi-akun (OAuth `youtube.readonly` + `openid`): tarik playlist & liked videos. Tidak ada scope tulis. Refresh token disimpan lokal di backend (sqlite `accounts.db`), tidak di-cloud.
- Antrian yang bikin nyaman dipakai: ganti urutan dengan drag, mode ulang satu lagu atau semua, shuffle per antrian, swipe artwork untuk ganti lagu.
- State tersimpan: riwayat pencarian, antrian, dan riwayat putar ikut tersimpan lewat SQLite (drift), jadi antar session tidak mulai dari nol. Riwayat putar jadi dasar rekomendasi "Paling sering" & "Baru-baru ini" di tab Untukmu.
- Lirik untuk lagu yang tersedia datanya. Yang berformat LRC disinkronkan dengan posisi putar, baris yang sedang dinyanyikan ditebalkan.
- Unduh lagu untuk offline di Android, disimpan ke penyimpanan dokumen aplikasi. Kalau sudah ada, pemutaran langsung baca file lokal, tidak perlu internet.
- Di web, beberapa tab bisa saling mengikuti: tab yang terakhir memulai putar yang menang, tab lainnya ikut jeda biar tidak ada dua suara sekaligus.

## Arsitektur singkat

Klien Flutter berbicara ke backend lewat HTTP (`app/lib/core/api.dart`). Backend yang menangani urusan berat seperti resolusi stream dan metadata lewat yt-dlp, lalu klien hanya tinggal memutar URL-nya via `audio_service` / `just_audio`.

Penyimpanan lokal klien memakai drift (SQLite). Ada file `app/lib/features/` untuk per-modul: `audio/` (handler pemutaran), `player/` (state controller), `search/`, `lyrics/`, dan `storage/` (DB + layanan unduh). Pemutaran, antrian, shuffle, sampai sinkronisasi antar tab semuanya dihubungkan lewat Provider (Riverpod).

Backend (`backend/`) menyediakan endpoint: `GET /search`, `GET /stream`, `GET /lyrics`, `GET /health`, dengan cache optional di Redis.

## Menjalankan

### Backend

```sh
cd backend
uv sync
cp .env.example .env   # isi kalau mau pakai key opsional
uv run uvicorn --app-dir . app.main:app --host 0.0.0.0 --port 8000
```

Tanpa `.env` pun backend langsung jalan; YouTube dan YouTube Music tidak butuh API key. Untuk CORS di web, set `CORS_ORIGINS=http://localhost:8080` (atau port tempat `flutter run -d chrome` jalan).

Ada juga `docker-compose.yml` untuk jalan pakai Docker termasuk Redis:

```sh
cd backend
docker compose up -d --build
```

> Catatan: Dockerfile dan compose ini belum sempat dijalankan saat pengembangan (Docker tidak terpasang di mesinnya), jadi statusnya "documented only, not validated". Kalau mau dipakai, perlu dites dulu di mesin yang ada Docker.

### Aplikasi Android

Backend harus bisa dijangkau HP. Untuk emulator, `app/lib/core/api.dart` sudah mengarah ke `http://10.0.2.2:8000`. Kalau pakai HP fisik, ganti base URL-nya dengan IP komputer dan pastikan port 8000 terbuka.

```sh
cd app
flutter run
# atau bangun APK
flutter build apk --debug
```

### Aplikasi web

Web diakses via browser, jadi backend harus di host yang bisa diakses browser tersebut. Untuk pengembangan lokal, jalankan backend di `localhost:8000` lalu:

```sh
cd app
flutter run -d chrome
```

Catatan untuk build web: drift butuh dua file di `app/web/` (`sqlite3.wasm` dan `drift_worker.dart.js`). Keduanya sudah ditaruh di sana, diambil dari rilis drift versi yang sesuai.

## Development

Backend: `uv run ruff check app tests` untuk lint, `uv run pytest` untuk test. Aplikasi: `flutter analyze` dan `flutter test`. CI di `.github/workflows/ci.yml` menjalankan semua itu otomatis tiap push ke `main`.

Generator untuk drift (`app_db.g.dart`) diproduksi dengan `dart run build_runner build` setiap tabel diganti.

## Akun YouTube (OAuth)

Untuk fitur multi-akun YouTube, butuh setup Google Cloud + OAuth Web application. Langkah lengkap di `docs/setup-google-oauth.md`. Ringkasan:

1. Buat project di Google Cloud Console.
2. Aktifkan YouTube Data API v3.
3. Buat OAuth client type "Web application", set redirect URI = `http://localhost:8000/youtube/callback`.
4. Copy `Client ID` + `Client Secret` ke `backend/.env`:
   ```
   GOOGLE_CLIENT_ID=...
   GOOGLE_CLIENT_SECRET=...
   YOUTUBE_CALLBACK_URI=http://localhost:8000/youtube/callback
   ```

Restart backend. Di app, tab Untukmu → "Tambah akun" → login Google → akun tersimpan di `backend/accounts.db`.

## Testing di HP (Android)

Toolchain yang dipakai:
- `E:\dev\flutter\bin` untuk `flutter`
- `E:\dev\jdk\jdk-17` untuk `JAVA_HOME`
- `E:\dev\android-sdk\platform-tools` untuk `adb`
- `E:\dev\pub-cache` untuk `PUB_CACHE`
- `E:\dev\gradle` untuk `GRADLE_USER_HOME`

Workflow:

```powershell
# Set toolchain (PowerShell)
$env:JAVA_HOME = 'E:\dev\jdk\jdk-17'
$env:PUB_CACHE = 'E:\dev\pub-cache'
$env:GRADLE_USER_HOME = 'E:\dev\gradle'
$env:ANDROID_HOME = 'E:\dev\android-sdk'
$env:ANDROID_SDK_ROOT = 'E:\dev\android-sdk'
$env:PATH = "E:\dev\flutter\bin;E:\dev\jdk\jdk-17\bin;" + $env:PATH

# Backend
cd E:\projek_abal2\MyMusic\backend
uv run uvicorn --app-dir . app.main:app --host 0.0.0.0 --port 8000

# Build + install
cd E:\projek_abal2\MyMusic\app
flutter build apk --debug
adb -s <serial> reverse tcp:8000 tcp:8000
adb -s <serial> install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s <serial> shell am start -n com.mymusic.mymusic/.MainActivity

# Lihat logcat untuk error
adb -s <serial> logcat | Select-String -Pattern "flutter|exception|error" -CaseSensitive:$false
```

Tes kritis yang harus dijalankan sebelum release:

1. **Login Google** — tab Untukmu → "Tambah akun" → consent page di browser → kembali ke app → akun muncul.
2. **Multi-akun** — tambah akun kedua, switch di antara keduanya.
3. **Search + play** — tab Cari → ketik lagu → Putar semua → mini player muncul.
4. **Riwayat putar** — tab Untukmu → "Paling sering" / "Baru-baru ini" berisi lagu yang baru diputar.
5. **Lock screen 5 menit** — play lagu → matikan layar → tunggu 5 menit → audio masih jalan → kontrol prev/pause/next di notification bekerja. Cek via `adb shell dumpsys media_session` harus `state=PLAYING(3)`.
6. **Tema dark/light** — toggle di toolbar, status bar ikut tema, kontras teks cukup.
7. **Language toggle** — saat ini Indonesia default, English belum di-toggle dari UI (toggle ada di code, tinggal UI hook).

## Catatan kecil

- Unduhan offline dan mode background adalah fitur native, jadi ikon/tombolnya tidak muncul di web.
- Akun YouTube: tiap orang yang menjalankan backend-nya sendiri punya `accounts.db` sendiri. Tidak ada cloud sync. Privasi tetap per-device.
- APK release memakai debug signing sementara, cukup untuk instal langsung. Untuk publikasi Play Store, siapkan signing key sendiri dan arahkan `android/app/build.gradle.kts` ke situ.