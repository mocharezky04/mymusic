# Verifikasi playback di HP

Catatan sesi pengecekan pemutaran dari pencarian sampai antrian, diuji langsung di HP fisik. Tujuannya biar ada jejak: apa yang dicek, bagaimana, hasilnya apa, dan masalah apa saja yang ditemukan lalu dibereskan.

## Peralatan dan pengaturan

- HP: Infinix X6833B (serial `1027525383001648`), resolusi 1080x2460, density 480.
- Aplikasi: `com.mymusic.mymusic`, APK debug.
- Backend: uvicorn di `localhost:8000`, backend MyMusic (FastAPI + yt-dlp).
- Pemetaan port: `adb reverse tcp:8000 tcp:8000`, APK dibangun dengan `--dart-define=API_BASE=http://127.0.0.1:8000`.
- Cara melihat kejadian di aplikasi: `adb logcat` filter tag `flutter`. Saat sesi ini berjalan, kode masih memakai `debugPrint` berawalan `MM` yang sudah dihapus setelah verifikasi selesai.
- Cara menyentuh layar lewat terminal: `adb shell input tap`, dibantu `uiautomator dump` untuk posisi elemen.

## Yang berhasil diverifikasi

Tabel di bawah ini ringkas hasilnya. Kolom "cara cek" pakai koordinat yang berlaku di HP tersebut pada sesi ini; kalau layout berubah, cari dulu lewat `uiautomator dump`.

| Hal yang dicek | Cara cek | Hasil |
| --- | --- | --- |
| Pencarian | Ketik "bts" di field search | 10 hasil tampil, `MM search q=bts n=10` |
| Putar semua | Tombol "Putar semua" sekitar (840,552) | Antrian termuat 10 lagu, langsung jalan (`MM applyQueue n=10 start=0 autoPlay=true`) |
| Putar satu lagu | Tap baris hasil | Antrian berisi 1 lagu dan langsung jalan |
| Play dan pause | Tombol di tengah transport sekitar (540,2200) | Posisi berhenti bertambah saat pause, lanjut lagi saat play |
| Ganti lagu | Tombol next (800,2200) dan prev (280,2200) | Indeks antrian berganti sesuai arah |
| Geser seek | Tarik slider di NowPlaying lalu lepas | Posisi melompat ke titik yang dituju dan lanjut main dari sana |
| Shuffle | Tombol shuffle (150,2200) | `MM shuffle ON order=...`, urutan acak; dot indikator menyala |
| Ulang otomatis | Tombol repeat (930,2200) | Siklus off → semua → satu → off |
| Simpan state | Tutup paksa aplikasi lalu buka lagi | Antrian, indeks, `shuffle=true`, `repeat=all` kembali (`MM restore n=... shuffle=true repeat=all`) |
| Tab | Tab Cari (270,2364) dan Antrian (810,2364) | Pindah tab lancar, state pemutaran tetap |

Hasil stream (durasi, posisi, tick streaming) dibaca dari log `MM tick` yang berganti tiap detik dan dari slider yang bergerak, bukan hanya dari tampilan.

## Masalah yang ditemukan dan perbaikannya

Ada tiga hal yang baru ketahuan saat sesi berjalan.

**1. Log restore rusak karena string disusun salah.** Baris `debugPrint` memakai tanda petik ganda di dalam string tanpa dipisah variabel, sehingga lognya error dan tidak pernah tampil. Diperbaiki dengan memindahkan nilai `shuffleOn` ke sebuah variabel dulu, baru dipakai di string.

**2. Restore gagal karena baris meta kembar.** Sebenarnya `MM restore FAIL` sudah muncul, tapi sumbernya belum jelas sampai log yang lebih detail ditambahkan di `readQueue()`. Setelah ditelusuri: tabel `MetaRows` tidak punya primary key. `upsertMeta` memakai `insertOrReplace`, dan tanpa primary key SQLite menganggap tiap baris elemen baru, jadi tiap kali menyimpan shuffle dan repeat, baris meta menumpuk. Akibatnya `getSingleOrNull` melempar "Bad state: Too many elements" dan restore tidak jadi. Perbaikannya: `getMeta` sekarang memakai `select().get()` lalu mengambil baris terakhir, dan `upsertMeta` menghapus dulu baris lama lalu menambah satu (dibungkus transaksi). `downloadFor` di tabel `DownloadsRows` yang juga tak punya primary key diberi penanganan yang sama. Karena pembenarannya di sisi kueri, tidak perlu bump schema version.

**3. UI tidak selalu terlihat oleh a11y dump.** Mini player dan tombol transport kadang tidak muncul sebagai node di `uiautomator dump`, jadi koordinatnya harus dicari dengan log, bukan hanya dari hierarki. Mini player berada di ketinggian yang berubah-ubah (sekitar y 2080 di sesi ini); tombol transport ada di baris y sekitar 2200. Posisi ini khusus untuk HP ini dan ukuran layar ini.

Ada juga catatan proses: menggabungkan build dan install dalam satu baris perintah PowerShell gagal dengan pesan "This command should be run from the root of your Flutter project". Solusinya build dijalankan lebih dulu tersendiri dengan direktori kerja `app`, lalu `adb install` menyusul.

## Catatan jujur

Tidak semua jalur kode ikut diuji ulang di sesi ini. Drag untuk mengubah urutan antrian dan gesture geser untuk ganti lagu dibangun di kode tapi belum lewat verifikasi di layar; begitu juga lirik dan unduhan offline. Kalau nanti dibuat verifikasi lanjutan, itu yang perlu diambil duluan. Alat uji yang dipakai pun masih manual (tap lewat adb), belum ada test otomatis UI. Bisa dipoles kapan saja.

Dokumen ini berhenti di sini karena memang tujuannya mencatat, bukan menggantikan pengujian penuh.