# Findings: InnerTube player request diff vs yt-dlp

Objektif: lagu di HP gagal resolve (`RELOAD_PAGE` / `LOGIN_REQUIRED` / `403 stream: 313`)
padahal yt-dlp dari IP yang sama (WiFi rumah) sukses 5/5. Diuji apakah penyebabnya IP
datacenter atau konfigurasi client yang dipakai package `youtube_explode_dart`.

## Metode

1. Jalankan yt-dlp 2026.08.19 dengan `--verbose` + `debug_printtraffic` (via
   `backend/.venv`) untuk video `JGwWNGJdvx8`, default client tanpa cookie apa pun.
2. Baca source `youtube_explode_dart-3.1.0` (`youtube_api_client.dart`,
   `stream_client.dart`, `video_controller.dart`, `watch_page.dart`).
3. Rekonstruksi request player dari PC (IP rumah) dengan script Dart berbasis
   `dart:io` saja untuk 4 varian client, bandingkan hasil playability.

## Hasil probe (PC, IP rumah, `JGwWNGJdvx8`)

| Varian | Status | Keterangan |
|---|---|---|
| A. VISIONOS (mirror persis yt-dlp) | OK | 27 streams, GET range 206, HEAD 200 |
| B. tv (TVHTML5 7.20251105.10.00) | UNPLAYABLE | `The page needs to be reloaded.` |
| C. androidVr (ANDROID_VR 1.56.21) | LOGIN_REQUIRED | `Sign in to confirm you're not a bot` |
| D. ios (IOS 20.10.4 + API key) | OK | 27 streams, tapi HEAD URL stream = 403 |

## Kesimpulan

- Gagal-nya tv/androidVr terjadi **identik dari IP rumah** — bukan soal IP, melainkan
  konfigurasi client lama yang ditolak server YouTube. Ini menjelaskan error di HP yang
  sama persis, padahal IP HP bersih.
- Client ios masih playable, tapi cek `HEAD` di `stream_client.dart` dapat 403 sehingga
  package melempar `YoutubeExplodeException(403 (stream: 313))` — persis error di HP.
- Solusi: pajang request layer sendiri yang mereplikasi client VISIONOS default yt-dlp
  (lihat `app/lib/features/audio/yt/visionos_client.dart`), lalu pakai ulang
  `youtube_explode_dart` untuk parsing dan solving lainnya.

## Request yt-dlp yang ditiru

`POST https://www.youtube.com/youtubei/v1/player?prettyPrint=false` (tanpa API key).

Header penting:
- `User-Agent`: Safari macOS (Vision), `Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) ...`
- `X-Youtube-Client-Name: 101`, `X-Youtube-Client-Version: 1.02`
- `Origin: https://www.youtube.com`
- `X-Goog-Visitor-Id`: visitor id dari halaman watch (ytcfg), tanpa perlu cookie khusus.

Body:
```json
{
  "context": {
    "client": {
      "clientName": "VISIONOS",
      "clientVersion": "1.02",
      "deviceMake": "Apple",
      "deviceModel": "RealityDevice17,1",
      "userAgent": "<Safari visionOS UA>",
      "osName": "visionOS",
      "osVersion": "26.5.23O471",
      "hl": "en",
      "timeZone": "UTC",
      "utcOffsetMinutes": 0
    }
  },
  "videoId": "<id>",
  "contentCheckOk": true,
  "racyCheckOk": true
}
```

## Verifikasi akhir

Dengan client VISIONOS di aplikasi (APK release ke HP):
- 4/4 resolve yang tercatat di logcat = `stream: local ok (visionos)`.
- 0 fallback ke backend. Semua lagu terputar.