# Akun YouTube — Keterbatasan & Cara Kerja

## OAuth flow

1. App tekan **Add account** → backend `GET /youtube/auth/start` return 302 ke `https://accounts.google.com/o/oauth2/v2/auth`.
2. User authorize di browser Google, lalu Google redirect ke `YOUTUBE_CALLBACK_URI` (di `.env`) = `http://127.0.0.1:8000/youtube/callback`.
3. Backend tukar `code` jadi `access_token` + `refresh_token`, simpan ke `account_store.py`, lalu render HTML dengan **meta-refresh 3 detik** ke `mymusic://youtube-connected?email=...&name=...` dan tombol "Buka MyMusic".
4. Custom scheme `mymusic://` di-handle oleh `MainActivity.kt` (intent-filter di `AndroidManifest.xml`) → `onNewIntent` kirim URI ke Flutter via `MethodChannel("mymusic/deeplink")`.
5. `MyMusicApp` di Flutter terima deep link → `accountsProvider.refresh()` → snackbar `Account linked: <email>`.
6. Sebagai fallback, `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` selalu refresh akun — jadi kalau user balik manual (tanpa tap link), akun tetap muncul.

## Yang disimpan

- `refresh_token` (offline access, untuk ambil `access_token` baru saat perlu)
- `channel_id`, `channel_title` (display name channel YouTube), `avatar_url`
- `email` (sebagai primary key)

## Yang TIDAK disimpan (by design, keterbatasan API)

### 1. Playlist Pribadi channel lain

YouTube Data API v3 dengan parameter `mine=true` HANYA mengembalikan playlist **yang dimiliki oleh channel yang sedang login** (channel id `mine`). Playlist "Pribadi" yang disimpan dari channel lain (mis. channel "Muse Indonesia", "KompasTV", dll) **tidak dapat diambil lewat API resmi** — harus scraping.

**Kebijakan:** app TIDAK scraping. Yang ditampilkan = playlist milik channel login saja. Untuk pindah akun, pakai toggle di header "YouTube Accounts".

### 2. Mix & Radio otomatis

YouTube Mix (playlist yang dibuat otomatis dari seed) tidak punya ID tetap yang bisa diminta lewat `mine=true`. Mix yang muncul di tab "Library → Pribadi" di YouTube UI kadang dari subscription feed, yang berbeda dari API `playlists` endpoint.

**Tampil di app:** Mix yang disimpan secara eksplisit sebagai playlist (oleh user lewat "Save to playlist") akan muncul jika channel itu yang login.

**Mix tersimpan (fitur baru):** User bisa menyimpan Mix YouTube (ID `RDxxxx`) ke database lokal via endpoint `GET /youtube/mix?mixId=RDxxxx`. Mix disimpan di tabel `SavedMixRows` di drift DB dan ditampilkan di tab For You sebagai section "Mix tersimpan". Data di-cache 30 menit di backend (in-memory, tanpa Redis). Saat user putar mix, app fetch ulang tracks dari backend.

### 3. Playlist "Liked videos" (LL)

Playlist "Liked videos" menggunakan ID khusus `LL`. Untuk fetch tracks, backend resolve playlist ID aktual via `channels.list?mine=true→contentDetails.relatedPlaylists.likes`, lalu pakai endpoint `playlistItems` dengan ID tersebut. Count diambil terpisah via `playlists?mine=true&id=LL`.

### 4. Playlist yang di-share publik

Playlist publik orang lain **bisa** diambil dengan parameter `channelId=<id>` (bukan `mine=true`), tapi app saat ini tidak support multi-channel browsing. Ini bukan keterbatasan, hanya fitur yang belum dibangun.

## Pagination

`fetch_playlists()` di `backend/app/google_yt.py` melakukan loop `nextPageToken` sampai habis, max 200 playlist per akun (guard loop tanpa akhir). Batas Google API untuk user-level quota: 10.000 unit/hari; 200 playlist × 1 unit = cukup untuk penggunaan normal.

## Referensi

- Google OAuth 2.0: https://developers.google.com/identity/protocols/oauth2
- YouTube Data API v3 — Playlists: https://developers.google.com/youtube/v3/docs/playlists/list
- YouTube Data API v3 — Channels (untuk `mine`): https://developers.google.com/youtube/v3/docs/channels/list
