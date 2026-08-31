# Impor History dari YouTube Takeout

## Apa ini

`watch-history.json` dari Google Takeout berisi riwayat tontonan YouTube — ID video, judul, channel, waktu tonton. MyMusic bisa impor ini ke database lokal (tabel `PlaybackHistoryRows`) sebagai sumber tambahan untuk "Paling sering" dan "Baru-baru ini".

## Status

⚠️ **Belum ada script otomatis** di MyMusic. Doc ini menjelaskan manual flow untuk saat ini, dan arah jika nanti mau diotomasi.

## Sumber Data

1. Buka https://takeout.google.com
2. Pilih hanya "YouTube dan YouTube Music"
3. Pilih "history" saja (tidak perlu subscriptions, playlists, dll.)
4. Format: JSON
5. Export → download ZIP
6. Ekstrak → ambil file `watch-history.json`

Struktur:
```json
[
  {
    "header": "YouTube",
    "title": "Coldplay - Fix You (Official Video)",
    "titleUrl": "https://www.youtube.com/watch?v=VPRjCeoBqrI",
    "subtitles": [{ "name": "Coldplay", "url": "..." }],
    "time": "2024-08-15T14:30:00.000Z"
  },
  ...
]
```

## Manual Flow (sekarang)

1. Simpan `watch-history.json` di HP (mis. `Download/`).
2. Buka MyMusic → tab Untukmu.
3. (Belum ada UI) — untuk sekarang: tidak ada cara impor di dalam app.

## Alur yang Akan Datang (rencana)

Kalau nanti mau dibuat, pendekatannya:

1. **File picker di app** — tambahkan tombol "Impor dari Takeout" di Settings (Settings belum ada, jadi mungkin taruh di tab Untukmu footer). Pakai `file_picker` package.
2. **Parse JSON** — ekstrak `titleUrl` (ID video), `title`, `subtitles[0].name` (channel/artist), `time` (timestamp).
3. **Insert ke drift** — tambahkan baris di `PlaybackHistoryRows`:
   ```sql
   INSERT INTO PlaybackHistoryRows (track_id, source, plays, last_played_at, ...)
   VALUES ('VPRjCeoBqrI', 'youtube', 1, <time>, ...)
   ```
4. **Invalidate providers** — panggil `ref.invalidate(recentPlaysProvider)` & `topPlaysProvider` agar "Paling sering" / "Baru-baru ini" ter-update.

## Kenapa Impor Penting

- Rekomendasi "Baru-baru ini" berdasarkan takeout jauh lebih akurat dari riwayat internal MyMusic saja, apalagi untuk user yang sudah lama pakai YouTube.
- Bisa langsung "lanjutkan" dari lagu yang belum ada di MyMusic.
- Tidak menambah konsumsi quota Data API (cuma satu kali parsing lokal).

## Catatan

- Takeout history biasanya punya 100-10.000+ entri. Insert satu-satu akan lambat. Pakai batch insert.
- Duplikat (lagu yang sama ditonton berulang kali) → agregat: tambahkan `plays++` di baris yang sudah ada, bukan insert baru. Ini otomatis di `recordPlay` lewat `ON CONFLICT ... DO UPDATE`.
- Format Takeout bisa berubah. Cek struktur JSON tiap kali download baru (Google kadang tambahkan field `products`, `activityControls`, dll. yang harus diabaikan).
- Privacy: `watch-history.json` berisi data pribadi. Setelah import, hapus file dari HP.

## File terkait (jika nanti diimplementasi)

- `app/lib/features/storage/app_db.dart` — schema `PlaybackHistoryRows`, method `recordPlay`
- `app/lib/features/player/player_provider.dart` — invalidate `recentPlaysProvider`/`topPlaysProvider`
- `app/lib/features/forYou/history_providers.dart` — providers
- Backend tidak terlibat — semua lokal di drift.
