# Setup login YouTube (Google Cloud)

Panduan sekali jalan untuk menyiapkan kredensial OAuth di Google Cloud Console. Tanpa langkah ini, fitur akun YouTube di aplikasi tetap tampil tapi backend bisa menolak karena belum dikonfigurasi.

## Yang akan dibuat

1. Project di Google Cloud Console.
2. YouTube Data API v3 aktif di project itu.
3. OAuth client tipe Web application.
4. Dua nilai: `GOOGLE_CLIENT_ID` dan `GOOGLE_CLIENT_SECRET`, diisi ke `.env` backend.

Waktu total sekitar 10 menit.

## 1. Buat project

Buka [Google Cloud Console](https://console.cloud.google.com/), login pakai Google. Pilih project dari dropdown atas, atau buat baru lewat tombol "New Project". Beri nama bebas, misalnya `mymusic`. Tidak perlu mengaktifkan billing, karena API YouTube untuk penggunaan pribadi model testing tidak dikenai tagihan.

## 2. Aktifkan YouTube Data API v3

- Dari menu kiri, ke "APIs & Services", lalu "Library".
- Cari "YouTube Data API v3", klik, lalu tombol "Enable".

## 3. Siapkan halaman persetujuan (consent screen)

- Buka "APIs & Services", lalu "OAuth consent screen".
- Pilih tipe "External" (umpan balik monitoring hanya untuk akun internal; kita butuh Testing).
- Isi nama aplikasi (cuma internal), dukungan email kamu, lalu simpan.
- Di bagian "Audience", ada mode Testing. Maksimal 100 pengguna, cukup untuk pribadi.
- Di "Test users", tambahkan alamat email semua akun Google yang mau dipakai login. Kalau dua akun, dua-duanya didaftarkan di sini.
- Publikasi ke Production tidak perlu selama pemakaian pribadi. Testing punya batasan: token akses kadaluarsa tiap 7 hari, tapi karena backend punya refresh token yang bisa meminta ulang, aplikasi tetap jalan tanpa perlu login ulang.

## 4. Buat OAuth client tipe Web application

- Buka "APIs & Services", lalu "Credentials".
- Klik "Create credentials", pilih "OAuth client ID".
- Application type: **Web application**.
- Beri nama bebas.
- Di bagian "Authorized redirect URIs", tambahkan:
  ```
  http://127.0.0.1:8000/youtube/callback
  ```
  URL ini harus persis sama dengan nilai `YOUTUBE_CALLBACK_URI` di `.env`, dan persis sama dengan yang dibaca server saat pertukaran kode.

Kenapa tipe Web bukan Desktop: tipe Desktop di Google hanya mengizinkan redirect ke loopback tanpa path. Format di atas punya path `/youtube/callback`, jadi wajib tipe Web application. Client secret yang muncul setelah pembuatan aman disimpan di backend pribadi; tidak pernah dikirim ke aplikasi.

- Setelah jadi, salin **Client ID** dan **Client secret**.

## 5. Isi `.env` backend

Di direktori `backend/`, salin `.env.example` jadi `.env` kalau belum ada, lalu isi:

```env
GOOGLE_CLIENT_ID=<client id dari konsol>
GOOGLE_CLIENT_SECRET=<client secret dari konsol>
YOUTUBE_CALLBACK_URI=http://127.0.0.1:8000/youtube/callback
```

`GOOGLE_CLIENT_SECRET` adalah wajib untuk alur ini. Tanpa nilai itu, backend tetap hidup, fitur akun tampil, tapi tiap ajakan login ditolak dengan pesan "belum dikonfigurasi".

## 6. Mulai backend dan tes alur

Jalankan backend seperti biasa:

```sh
cd backend
uv run uvicorn --app-dir . app.main:app --host 0.0.0.0 --port 8000
```

Lalu dari HP yang terhubung `adb reverse tcp:8000 tcp:8000`:

- Buka aplikasi, ke tab "Untukmu", tekan "Hubungkan YouTube".
- Browser Google muncul dengan pemilih akun.
- Login pakai salah satu akun test user, setujui izin (baca saja), lalu kembali ke aplikasi otomatis lewat skema `mymusic://`.

Di aplikasi, daftar playlist dan Liked dari akun itu tampil di tab "Untukmu".

## Catatan: kenapa selalu muncul pemilih akun

Saat membuat URL OAuth, backend menambahkan parameter `prompt=consent` dan `access_type=offline`. Dua ini yang memungkinkan alur multi akun:

- `prompt=consent` membuat Google selalu menampilkan daftar akun, tidak diam-diam memakai sesi browser terakhir. Tanpa ini, muncul akun terakhir terus.
- `access_type=offline` memberi refresh token supaya backend bisa bermain tanpa login lagi setiap sore.

Setiap akun baru melewati alur yang sama. Backend menyimpan tiap akun sebagai baris terpisah (kunci: email), dan memperbarui token akun yang sudah ada tanpa menyentuh akun lain.

## Kalau ada masalah

- 403 / "access blocked" saat consent: akun tersebut belum didaftarkan di Test users, atau project masih dalam tahap Pembuatan consent.
- Redirect jadi halaman "redirect_uri_mismatch": URL redirect di konsol tidak persis sama dengan `YOUTUBE_CALLBACK_URI` di `.env`.
- `/youtube/me` mengembalikan 503: `GOOGLE_CLIENT_ID` atau `GOOGLE_CLIENT_SECRET` kosong.