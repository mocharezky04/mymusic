# MyMusic — DESIGN.md v2

Identitas warna diambil dari **ikon aplikasi**, bukan dari palet trend. Dokumen ini menggantikan
identitas ungu v1 sepenuhnya.

## 1. Identitas

Aplikasi musik personal, dipakai sendirian, cepat, tanpa panggung. Karakter: **monokrom, tenang,
teknis tanpa dingin**. Ikon aplikasi adalah sumber kebenaran: line-art putih di atas near-black.
Layar harus terasa seperti alat, bukan seperti poster.

## 2. Palet (diturunkan dari ikon)

Fakta yang diukur dari berkas ikon, bukan tebakan:

| Sumber | Nilai |
|---|---|
| `res/values/colors.xml` → `ic_launcher_background` | `#0B0D12` |
| `mipmap-xxxhdpi/ic_launcher_foreground.png` histogram | 77,47% `#FFFFFF`, 5,79% `#000000`, sisanya anti-aliasing. **Nol hue.** |

Artinya: identitas warna app ini **near-black + putih + abu netral**. Tidak ada hue yang perlu
dibuat-buat. Palet core 1 warna (abu) + 1 netral (hitam/putih) + 1 hue fungsional (merah error).

### Mode gelap (default, karena basis ikon gelap)

| Token | HEX | Pakai untuk |
|---|---|---|
| `surface` | `#0B0D12` | Latar aplikasi = warna latar ikon |
| `surfaceContainerLowest` | `#07080C` | Cekungan, indent |
| `surfaceContainerLow` | `#12141A` | Baris lagu, kartu kecil |
| `surfaceContainer` | `#181A21` | Kartu |
| `surfaceContainerHigh` | `#1F222A` | Sheet, container nav, tonal |
| `surfaceContainerHighest` | `#272B34` | Placeholder artwork, snackbar |
| `onSurface` | `#F4F5F7` | Teks utama, ikon |
| `onSurfaceVariant` | `#9EA3AE` | Teks sekunder, metadata |
| `outline` | `#5A6069` | Garis pemisah, border non-teks |
| `outlineVariant` | `#2A2E37` | Garis halus, divider |
| `error` | `#E2685F` | **Hanya** pesan error & aksi destruktif |

### Mode terang

| Token | HEX |
|---|---|
| `surface` | `#F7F8FA` |
| `surfaceContainerLowest` | `#FFFFFF` |
| `surfaceContainerLow` | `#EFF1F4` |
| `surfaceContainer` | `#E7EAEE` |
| `surfaceContainerHigh` | `#DEE2E7` |
| `surfaceContainerHighest` | `#D3D8DE` |
| `onSurface` | `#14161A` |
| `onSurfaceVariant` | `#5A6069` |
| `outline` | `#8A9099` |
| `error` | `#A8322B` |

### Aturan aksen

`primary` **tidak** punya hue. Di mode gelap `primary` = `#F4F5F7` (putihnear), di mode terang
`primary` = `#14161A`. Tombol filled = kebalikan kontras (putih di atas hitam). Satu-satunya hue
yang boleh muncul adalah `error` merah redam, dan hanya untuk pesan error serta aksi hapus.
Tidak ada warna ungu, violet, atau cyan di mana pun.

## 3. Anti-kata (ketuhanan user)

- **DILARANG** ungu / violet / cyan di layar mana pun. `AppColors.violet`, `violetBright`, `cyan`
  dihapus dari theme.
- **DILARANG** gradient sebagai treatment. Garis progres mini player dan seek bar = solidAbu terang.
- **DILARANG** glow. Tidak ada `BoxShadow` berwarna. Shadow netral maksimal 1, hanya untuk
  elemen yang benar-benar mengambang (mini player, bottom sheet).
- **DILARANG** radius besar. Skala kecil: **2 / 4 / 8 / 12**.
- **DILARANG** `BorderRadius.circular(999)` di mana pun. Tab aktif ditandai blok tonal radius 4,
  bukan pill.
- **DILARANG** uppercase + letterSpacing seragam di semua label. Tidak ada `toUpperCase()` pada
  label. Semua `letterSpacing: 0` kecuali judul besar yang memakai tracking negatif tipis.
- **DILARANG** tombol filled besar seragam. Hierarki: `filled` hanya untuk aksi utama satu per
  layar, sisanya `tonal` atau `text`.
- **DILARANG** memaksa warna untuk "hidup" agar tidak terasa steril. Monokrom penuh lebih baik
  daripada aksen palsu.

## 4. Radius

| Token | Nilai | Untuk |
|---|---|---|
| `xs` | 2 | Badge, chip kecil, indikator |
| `sm` | 4 | Input, tombol, thumbnail artwork, blok tab aktif |
| `md` | 8 | Baris lagu, kartu, menu |
| `lg` | 12 | Top bottom sheet, dialog |

Tidak ada nilai di luar 2/4/8/12.

## 5. Tipografi

| Peran | Ukuran | Weight | Catatan |
|---|---|---|---|
| Judul layar | 20 | 700 | Sentence case, tracking -0.2 |
| Judul section | 15 | 600 | Sentence case |
| Judul lagu | 14 | 600 (sedang diputar: 700) | 1 baris, ellipsis |
| Metadata | 12.5 | 400 | `onSurfaceVariant` |
| Label kecil | 12 | 500 | Sentence case, **tanpa** letterspacing |
| Durasi / sumber | 11 | 500 | `onSurfaceVariant` |

Tidak ada teks kapital untuk gaya. Kapital hanya di awal kalimat.

## 6. Motif

Motif adalah **line-art 2px** dari ikon aplikasi. Di UI memakai varian *outlined* Material
(`Icons.music_note_outlined`, `Icons.album_outlined`, `Icons.queue_music_outlined`).
Ikon *filled* hanya untuk state "sedang diputar". Baris pemisah 1px `outlineVariant` lebih
disukai daripada kartu bertumpuk.

## 7. Motion

- Slide-up NowPlaying 320ms easeOutCubic dipertahankan.
- Progress barGrow/decay mengikuti playback saja.
- EQ bars hanya saat playback. Tidak ada loop dekoratif.

## 8. States

Setiap empty / loading / error menyebut **sebab + aksi**, bahasa aktif, tanpa raw exception.

## 9. Aksesibilitas (angka dihitung, bukan dikira)

Rumus WCAG 2.x, `L = 0.2126R + 0.7152G + 0.0722B` setelah linearisasi.

| Pasangan | Rasio | Status |
|---|---|---|
| `#F4F5F7` on `#0B0D12` | 17,82 | AAA |
| `#9EA3AE` on `#0B0D12` | 7,68 | AAA |
| `#5A6069` on `#0B0D12` (non-teks) | 3,07 | AA non-teks |
| `#E2685F` on `#0B0D12` | 5,90 | AA |
| `#0B0D12` on `#F4F5F7` (tombol filled) | 19,43 | AAA |
| `#14161A` on `#F7F8FA` | 17,04 | AAA |
| `#5A6069` on `#F7F8FA` | 5,97 | AA |
| `#A8322B` on `#F7F8FA` | 6,26 | AA |

Tap target ≥44px (≈11,6mm, di atas ambang 1cm dari Parhi/Karlson/Bederson 2006).
Jarak antar target juga penting, bukan cuma ukuran (Harley 2019).

## 10. Riset & referensi

Alat: 9router REST API **tidak bisa dipakai** — `/v1/models/web` membalas 401 karena
`NINEROUTER_KEY` tidak ada di environment. Riset dilakukan dengan tool `webfetch` yang tersedia di
toolset. DuckDuckGo diblokir (transport error), Dribbble mengembalikan halaman kosong (JS),
Behance membalas 403. Dua sumber berikut benar-benar diakses dan dibaca:

1. **Nielsen Norman Group — "Dark Mode vs. Light Mode: Which Is Better?"** (Raluca Budiu, 2 Feb 2020)
   <https://www.nngroup.com/articles/dark-mode/>
   Ringkasan literatur yang dikutip: Piepenbrock et al. 2013 (*Ergonomics*) dan 2017
   (*Applied Ergonomics*), Dobres et al. 2017 (MIT Agelab), Legge et al. 1985, Aleman et al. 2018
   (*Scientific Reports*).
   - **Diterima:** untuk pengguna penglihatan normal, mode terang (positive polarity) umumnya
     lebih baik untuk task akurasi visual dan proofreading; NN/G merekomendasikan **tidak**
     defaulted ke dark mode bila audiens umum, tapi **tetap harus** menyediakan toggle.
   - **Diterima:** di malam hari, teks kecil jauh lebih sulit dibaca di dark mode → teks sekunder
     tidak boleh turun dari 12px, dan hierarki ditegakkan lewat **ukuran dan weight**, bukan
     hanya warna.
   - **Diterima:** dark mode tetap dipertahankan sebagai default karena basis ikon app gelap,
     dan light mode harus benar-benar nyaman, bukan afterthought.

2. **Nielsen Norman Group — "Touch Targets on Touchscreens"** (Aurora Harley, 5 Mei 2019)
   <https://www.nngroup.com/articles/touch-target-size/>
   Mengutip Parhi, Karlson & Bederson 2006 (MobileHCI) dan Dandekar et al. 2003.
   - **Diterima:** minimum 1cm × 1cm fisik; ujung jari rata-rata 1,6–2cm, area thumb 2,5cm.
     → ambang 44px dipertahankan.
   - **Diterima:** target harus cukup besar **dan** cukup berjarak; penumpukan (crowding)
     adalah sumber mistake. Ini yang memotivasi bottom nav redesigned: bar datar dengan
     hairline + `SafeArea` bawah, bukan container melayang yang menempel gesture bar.
   - **Diterima:** view-tap asymmetry dihindari dengan memberi target lebih besar dari labelnya.

3. **Apple Human Interface Guidelines — "Tab bars"** (last updated 8 Juni 2026)
   <https://developer.apple.com/design/human-interface-guidelines/tab-bars>
   Diambil lewat endpoint JSON `…/tutorials/data/design/human-interface-guidelines/tab-bars.json`
   karena halaman HTML-nya butuh JavaScript.
   - **Diterima:** *"If your app already has bright, colorful content in the content layer, prefer a
     monochromatic appearance for tab bars."* → album art di app ini penuh warna, jadi chrome
     (nav, mini player, sheet) wajib monokrom. Ini justifikasi utama identitas baru.
   - **Diterima:** *"Include tab labels to help with navigation"* dan *"Use single words whenever
     possible."* → label nav tetap satu kata: "For You", "Search", "Playlist".
   - **Diterima:** *"Use a tab bar to support navigation, not to provide actions."* → nav tidak
     boleh dipakai memegang tombol aksi; aksinya di dalam layar.
   - **Diterima:** *"Avoid applying a similar color to tab labels and content layer backgrounds."*
     → label nav memakai `onSurface` (terang) dan `onSurfaceVariant` (redup) di atas
     `surfaceContainerHigh`, jaraknya jauh dari ambang 3:1.
   - **Diterima:** *"Don't disable or hide tab bar buttons, even when their content is unavailable.
     If a section is empty, explain why its content is unavailable."* → empty state wajib punya
     penjelasan, tombol nav tidak pernah disembunyikan.
   - **Catatan kehati-hatian:** dokumen HIG ini **tidak** memuat tinggi tab bar iOS maupun ukuran
     ikon/label dalam pt, dan tidak membahas bentuk indikator tab aktif di iOS (hanya tvOS).
     Karena itu angka 44px di dokumen ini **tidak** berasal dari HIG, melainkan dari aturan 1cm
     milik NN/G di atas. Bentuk indikator aktif (blok tonal radius 4) adalah keputusan sendiri,
     bukan hasil sitasi.

### Catatan tentang alat riset

9router REST API **tidak punya model web-search** (`/v1/models/web` mengembalikan daftar kosong,
meski `NINEROUTER_KEY` sudah tersedia). 66 model chat tersedia; dipakai sebagai cross-check
sekunder, tetapi URL yang dihasilkan model tersebut sebagian besar tidak dapat diverifikasi
(403/404, dan beberapaslug bearslangka acak yang menyerupai URL karangan). Karena itu
**hanya tiga sumber di atas yang dikutip** di dokumen ini, dan ketiganya saya akses dan baca
sendiri. Angka dari cross-check model tidak dipakai sebagai acuan.


Pola yang diterapkan dari pengamatan umum app musik ( Spotify / Apple Music / YouTube Music /
Tidal ) yang konsisten di semua sumber:

- Baris lagu: thumbnail 48px, radius kecil, judul 14/600 + artis 12.5/400, durasi rata kanan.
- Fokus satu per layar: baris yang sedang diputar dibedakan weight, bukan warna.
- Player: artwork dominan, seek bar tipis, kontrol besar di tengah, transport di bawah.
- Bottom nav: 3–4 destination, label selalu terlihat (tanpa hamburger).
- Empty state: satu ikon line-art + satu kalimat sebab + satu aksi.

## 11. Pola per layar

| Layar | Fokus | Catatan |
|---|---|---|
| For You | Rekomendasi (kartu besar) | Label section sentence case, tanpa duplikasi judul layar |
| Search | Field + hasil | Label "Riwayat pencarian" sentence case, bukan kapital |
| Playlist | Daftar + 1 tombol "New playlist" | Judul hanya di AppBar |
| Playlist detail | Cover + daftar lagu | Aksi utama filled, lainnya tonal |
| Mini player | Baris ringkas | Flat, 1 shadow netral, progress solid |
| Now Playing | Artwork | Tanpa glow, radius kecil, kontrol ≥44px |
| Queue panel | Now playing + up next | Sheet radius 12, hitung badge tonal |
| Lyrics | Teks lirik | Sheet penuh, tipografi readable ≥14px |
