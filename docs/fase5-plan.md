# Fase 5 Plan — MyMusic

## Tujuan
Melengkapi fitur akun YouTube multi-akun, verifikasi E2E di HP, dan dokumentasi final sebelum release.

## 8 Langkah Eksekusi Urut

### 0. Simpan Rencana
Tulis ke docs/fase5-plan.md sebelum mulai eksekusi.

### 1. Fix Tema Minor
- **Dark Theme:**
  - Status bar gelap: pakai SystemChrome.setSystemUIOverlayStyle di main.dart
  - Tombol Outline warna: atur borderSide ke AppColors.onSurface di widget tombol outlined
- **Light Theme:**
  - AppBar text-warna: foregroundColor: AppColors.primary
  - Mini player progress bar: warnanya AppColors.onSurfaceVariant saat isPlaying=false
  - Queue list separator garis: tebal/warna gelap AppColors.divider

### 2. Background Playback dengan audio_service
Ikuti PERSIS dokumentasi package audio_service (com.ryanheise.audioservice):
- Tambah dependency audio_service ke pubspec.yaml
- Buat AudioService.init() di main.dart
- Buat class AudioServiceService yang extends BaseAudioService
- Register service di AndroidManifest dengan:
  - android:name="com.ryanheise.audioservice.AudioService"
  - android:foregroundService="true"
  - android:foregroundServiceType="mediaPlayback"
  - Filter: com.ryanheise.audioservice.AudioServiceBroadcast dan com.ryanheise.audioservice.AudioServiceWidget
  - MainActivity extends AudioServiceActivity
- Buat AudioHandler yang berkomunikasi ke UI (mini player, now playing)
- Audio focus auto-handle oleh package (pause saat ada panggilan, resume setelah)

### 3. Language Toggle (id/en, default Indonesia)
- Tambah shared preferences untuk menyimpan locale terpilih
- Gunakan package intl atau Map-based i18n sederhana
- Saat English dipilih: "Untukmu" → "For You", "Baca cepat" → "Recently played", "Cari" → "Search"
- Indonesia tetap default; opsi tukar di Settings

### 4. flutter analyze + flutter test
- Pastikan ruff check bersih + semua test lolos
- Perbaiki issue jika ada sebelum build

### 5. flutter build apk --debug
- Generate di build/app/outputs/flutter-apk/app-debug.apk
- Verifikasi APK bisa di-install ke HP

### 6. Instruksi Install ke HP + Tes Layar Mati 5 Menit
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- `adb -s <serial> shell am force-stop com.mymusic.mymusic` (fresh start)
- Buka app → login Google → tambah akun → cakup fitur
- **Tes kritis**: mulai lagu → matikan layar 5 menit → audio masih bunyi → kontrol next/pause muncul di lock screen ✅
- Screenshot tiap layar untuk dokumentasi

### 7. Dokumentasi (Fase 5 Files)
- `docs/impor-history-takeout.md` — cara impor CSV Takeout YouTube ke DB drift (opsional)
- `docs/youtube-account.md` — update alur login HTML, multi-akun, refresh profile, disconnect
- `README.md` — catat cara running backend, kredensial .env, cara tes, dan catatan desain

### 8. Ringkasan Lengkap
- Fitur yang sudah selesai (Fase 0–4)
- Cara tes tiap fitur
- Daftar keputusan desain (url_launcher+poll bukan app_links, recordPlay 1 baris per track, null-channel → playlist kosong, dark default, audio_service buat background playback, dll)

---

Setelah langkah 8 selesai, Fase 5 dianggap tuntas dan siap untuk review/ release.