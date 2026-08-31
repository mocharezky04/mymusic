# Deploy Backend ke Render (Free Web Service)

## Prasyarat

- Akun GitHub (repo code sudah di-push)
- Akun Render (gratis, tanpa kartu kredit): https://dashboard.render.com/register
- Akses ke Google Cloud Console (untuk OAuth redirect URI)

## Langkah 1: Generate API Key

Di laptop, jalankan:

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Copy output-nya. Ini adalah API key yang akan dipakai app dan backend.

## Langkah 2: Buat Akun Render & Web Service

1. Buka https://dashboard.render.com → **Sign Up** dengan GitHub (gratis)
2. Setelah login, klik **New +** → **Web Service**
3. Klik **Build and deploy from a Git repository** → **Next**
4. Klik **Connect GitHub** → pilih repo `MyMusic` (atau nama repo kamu)
5. Isi konfigurasi:
   - **Name**: `mymusic-backend` (atau nama lain)
   - **Region**: `Singapore` (SG) — paling dekat Indonesia
   - **Branch**: `main`
   - **Runtime**: `Docker`
   - **Instance Type**: `Free`
6. Di bagian **Environment Variables**, tambahkan satu per satu ( klik **Add Environment Variable** untuk setiap baris):
   - `GOOGLE_CLIENT_ID` = (client ID dari Google Cloud Console)
   - `GOOGLE_CLIENT_SECRET` = (client secret dari Google Cloud Console)
   - `YOUTUBE_CALLBACK_URI` = `https://mymusic-backend.onrender.com/youtube/callback` (ganti nama service kalau berbeda)
   - `LASTFM_API_KEY` = (opsional, kosongkan jika tidak ada)
   - `API_KEY` = (API key dari Langkah 1)
   - `PORT` = `8000` (Render free default, biasanya otomatis tapi aman di-set manual)
7. Klik **Create Web Service**
8. Tunggu build & deploy (~3-5 menit). Render akan clone repo, build Dockerfile, lalu start uvicorn.

## Langkah 3: Set Redirect URI di Google Cloud Console

1. Buka https://console.cloud.google.com
2. Pilih project yang benar
3. Klik **APIs & Services** → **Credentials**
4. Klik OAuth 2.0 Client ID yang dipakai
5. Di bagian **Authorized redirect URIs**, tambahkan:
   ```
   https://mymusic-backend.onrender.com/youtube/callback
   ```
6. Klik **Save**

## Langkah 4: Verifikasi Backend

Buka browser, akses:

```
https://mymusic-backend.onrender.com/health
```

Response harus: `{"status":"ok"}`

Catatan: Request pertama setelah sleep akan lambat (~30-60 detik cold start).

## Langkah 5: Build APK dengan URL Cloud

Di laptop, buka terminal di folder `app/`:

```bash
flutter build apk --dart-define=API_BASE=https://mymusic-backend.onrender.com --dart-define=API_KEY=<api-key-dari-langkah-1>
```

Install APK ke HP:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Langkah 6: Verifikasi di HP

Di HP (TANPA adb reverse, TANPA backend lokal):
1. Buka MyMusic
2. Test search → harus jalan
3. Test rekomendasi → harus jalan
4. Test playlist → harus jalan
5. Test putar lagu → harus jalan
6. Catat cold start time (service sleep setelah ~15 menit inaktif)

## Deploy Ulang

Render auto-deploy setiap push ke branch `main`. Untuk deploy manual:
1. Buka https://dashboard.render.com → pilih service
2. Klik **Manual Deploy** → **Deploy latest commit**

Atau cukup push ke GitHub, Render otomatis rebuild.

## Update yt-dlp

Edit `Dockerfile`, tambah baris ini SETELAH `RUN uv sync --no-dev`:

```dockerfile
RUN uv run pip install --upgrade yt-dlp
```

Lalu push ulang — Render auto-deploy.

## Keterbatasan Free Tier

- **Sleep**: Service tidur setelah ~15 menit tidak ada request
- **Cold start**: Saat service bangun dari tidur, butuh ~30-60 detik
- **CPU**: 0.1 GB RAM / shared CPU (cukup untuk uvicorn + yt-dlp)
- **Storage**: Filesystem bersifat ephemeral (cache hilang saat sleep)
- **Redis**: Tidak tersedia → pakai in-memory cache (sudah default)
- **Bandwidth**: 100 GB/bulan (lebih dari cukup untuk streaming audio)
- **Build limit**: 500 detik/build (cukup untuk Dockerfile sederhana)

## Environment Variables (Ringkasan)

| Variable | Required | Default | Keterangan |
|----------|----------|---------|------------|
| `GOOGLE_CLIENT_ID` | Ya (untuk YouTube) | - | OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Ya (untuk YouTube) | - | OAuth client secret |
| `YOUTUBE_CALLBACK_URI` | Ya (untuk YouTube) | - | `https://<service>.onrender.com/youtube/callback` |
| `API_KEY` | Tidak | `None` | Jika di-set, semua request harus sertakan header `X-API-Key` |
| `LASTFM_API_KEY` | Tidak | `None` | Untuk rekomendasi berbasis Last.fm |
| `PORT` | Tidak | `8000` | Render free default |

**Semua env vars di-set di Render Dashboard → Environment tab. TIDAK di-commit ke git.**

## OAuth Redirect URI Checklist

Pastikan di Google Cloud Console ada redirect URI ini:
```
https://mymusic-backend.onrender.com/youtube/callback
```
(ganti `mymusic-backend` dengan nama service Render kamu jika berbeda)

## YouTube IP Blocking

Jika YouTube memblokir IP datacenter Render, error yang muncul:
- `"Sign in to confirm you're not a bot"` saat `/stream`
- `yt-dlp` gagal extract URL

**Solusi**: Tidak ada solusi sederhana untuk free tier. YouTube aktif memblokir IP datacenter. Ini keterbatasan yang sudah diketahui.

## Rollback

Jika ada masalah, klik **Manual Deploy** → **Rollback to previous deploy** di dashboard Render.
