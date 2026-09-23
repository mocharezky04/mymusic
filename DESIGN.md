# MyMusic — DESIGN.md

## Identitas
Aplikasi musik mobile-first dengan karakter "malam": gelap, santai, personal, akrab — bukan korporat. Kepribadian: tenang, percaya diri tanpa norak.

## Palet (nilai persis dari app/lib/core/theme.dart — JANGAN tambah warna baru)
- ink #0A0A12 (surface gelap), inkSoft #14141F
- violet #7C5CFF = aksen utama, satu-satunya warna identitas
- violetBright #9D7BFF = primary terang
- cyan #22D3EE = HANYA untuk indikator progres/level; dosis maksimal satu keluarga elemen per layar
- pinkCoral #FF5C8A = error/destruktif saja
- muted #9A94C4 = teks sekunder; mode terang pakai paper #F4F7FD dan turunan yang sudah ada
- Palet inti maksimal 2-3 warna + 1 aksen.

## Tipografi
- Display 26/700 hanya untuk judul layar bernilai — BUKAN semua teks kapital.
- Uppercase + letterspacing HANYA untuk micro-label ≤12px (mis. "RIWAYAT", "ANTRIAN · 5").
- Body 13.5–16; teks sekunder 11–13.5.

## Radius & elevasi
- Pakai AppRadius (sm=8, md=14, lg=20, xl=28). Pill 999 HANYA untuk nav bawah dan chip fungsional — bukan semua tombol/input/badge.
- Shadow hanya menandai hierarki: maksimal 1-2 elemen terangkat per layar. Glow ungu maksimal 1 elemen per layar; default TANPA glow.

## Motif identitas (satu-satunya yang berulang)
- Gradient violet→cyan = MOTIF TUNGGAL, hanya untuk garis progres mini player dan seek bar aktif. Dilarang dipakai di tempat lain.
- EQ bars = indikator status "sedang diputar" (bergerak hanya saat playback).

## Motion
- Signature: transisi slide-up NowPlaying 320ms easeOutCubic — dipertahankan.
- Selebihnya hemat: tanpa fade-up bertumpuk, tanpa bounce, tanpa loop dekoratif. Animasi hanya dengan tujuan tertulis.

## States
Empty/loading/error tiap layar menyebut sebab + aksi berikutnya, dalam bahasa aktif.

## Aksesibilitas
Kontras WCAG AA dihitung dengan rumus; tap target ≥44px; tidak ada yang terpotong; keyboard tidak menutupi input fokus.

## Delivery Gate
Checklist "Filter Anti-Slop" nomor 7 harus lolos sebelum lapor.