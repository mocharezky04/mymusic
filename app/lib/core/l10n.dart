import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageProvider = StateProvider<String>((ref) => 'en');

class L10n {
  final String locale;
  L10n(this.locale);

  bool get isEn => locale != 'id';

  String _t(String en, String id) => isEn ? en : id;

  // Tabs & home
  String get forYou => _t('For You', 'Untukmu');
  String get recentlyPlayed => _t('Recently played', 'Baca cepat');
  String get search => _t('Search', 'Cari');
  String get queue => _t('Queue', 'Antrian');
  String get changeTheme => _t('Change theme', 'Ganti tema');
  String get changeLanguage => _t('Language', 'Ganti bahasa');

  // Search
  String get searchHint => _t('Search songs, artists, or materials…', 'Cari lagu, artis, atau materi…');
  String get searchFailed => _t('Search failed', 'Gagal mencari');
  String get searchRetry => _t('Try another keyword or change the source.', 'Coba kata kunci lain atau ubah sumber pencarian.');
  String get searchEmpty => _t('Type above to search. Your search plan will appear here.', 'Ketik di atas untuk mencari. Rencana pencarianmu akan muncul di sini.');
  String get searchNoResults => _t('No results', 'Tidak ada hasil');
  String get searchStartHere => _t('Start here', 'Mulai dari sini');
  String get searchPlanLabel => _t('YOUR PLAN', 'RENCANA INI');
  String get searchClear => _t('Clear', 'Bersihkan');
  String searchResults(int count) => _t('RESULTS · $count', 'HASIL · $count');
  String get playAll => _t('Play all', 'Putar semua');
  String get moreActions => _t('More actions', 'Aksi lain');
  String get playNow => _t('Play now', 'Putar sekarang');
  String get playNext => _t('Play next', 'Putar berikutnya');
  String get addToQueue => _t('Add to queue', 'Tambahkan ke antrian');
  String get addToQueueShort => _t('Add to queue', 'Tambah ke antrian');

  // Queue
  String get queueEmptyTitle => _t('Queue is empty', 'Antrian kosong');
  String get queueEmptySubtitle => _t('Search a song then tap the add button, or play straight from results.', 'Cari lagu lalu tekan tombol tambah, atau langsung mainkan dari hasil pencarian.');
  String queueCount(int count) => _t('QUEUE · $count', 'ANTRIAN · $count');
  String get clearQueue => _t('Clear queue', 'Kosongkan antrian');

  // Player / NowPlaying
  String get nowPlaying => _t('NOW PLAYING', 'SEDANG DIPUTAR');
  String get lyrics => _t('Lyrics', 'Lirik');
  String get noPlayer => _t('Nothing playing yet', 'Belum ada yang diputar');
  String get playError => _t('A playback error occurred', 'Terjadi kesalahan pemutaran');
  String get loadQueueError => _t('Failed to load playback queue', 'Gagal memuat antrian audio');
  String get sourceNotPlayable => _t('This source cannot be played yet', 'Sumber ini belum bisa diputar');
  String get downloadSavedForOffline => _t('saved for offline', 'tersimpan untuk offline');
  String get downloadFailed => _t('Download failed', 'Unduhan gagal');
  String get downloadRemoved => _t('Download removed', 'Unduhan dihapus');
  String get removeDownload => _t('Remove download', 'Hapus unduhan');
  String get saveForOffline => _t('Save for offline', 'Simpan untuk offline');

  // Repeat
  String get repeatAll => _t('Repeat all', 'Ulang semua');
  String get repeatOne => _t('Repeat one', 'Ulang satu');
  String get repeatOff => _t('Repeat off', 'Ulang mati');

  // Lyrics
  String lyricsTitle(String title) => _t('Lyrics — $title', 'Lirik — $title');
  String get lyricsNotFound => _t('Lyrics not found.', 'Lirik tidak ditemukan.');
  String get lyricsNotInDb => _t('The lyrics database does not have this song.', 'DB lirik tidak punya lagu ini.');

  // For You / Accounts
  String get noHistory => _t('No playback history yet', 'Belum ada riwayat putar');
  String get topPlayed => _t('Top played', 'Paling sering');
  String get recentlyPlayedTitle => _t('Recently played', 'Baru-baru ini');
  String topSubtitle(int count) => _t('$count songs · from your history', '$count lagu · dari riwayatmu');
  String recentSubtitle(int count) => _t('$count songs · continue', '$count lagu · lanjutkan');
  String get recommendedForYou => _t('Recommended for you', 'Direkomendasikan untukmu');
  String get accountsLabel => _t('YOUTUBE ACCOUNTS', 'AKUN YOUTUBE');
  String get noPlaylists => _t('No playlists', 'Tidak ada playlist');
  String get noAccounts => _t('No YouTube accounts', 'Belum ada akun YouTube');
  String get addAccount => _t('Add account', 'Tambah akun');
  String get removeActiveAccount => _t('Remove active account', 'Copot akun aktif');
  String get yours => _t('Yours', 'Punya saya');
  String get likedPlaylists => _t('Liked playlists', 'Playlist & video disukai');
  String get cantOpenBrowser => _t('Cannot open browser', 'Tidak bisa membuka browser');
  String get accountsNotConfigured => _t('This feature is not configured on the server', 'Fitur akun belum dikonfigurasi di server');
  String get playlistFromSelected => _t('Playlists are shown from the account selected above.', 'Playlist tampil dari akun yang dipilih di atas.');
  String get connectYouTube => _t('Connect YouTube account', 'Hubungkan akun YouTube');
  String get connectYouTubeSubtitle => _t('View and play playlists and liked videos from your account.', 'Lihat dan putar playlist serta video yang disukai dari akunmu.');
  String get login => _t('Login', 'Login');
  String loadPlaylistError(String err) => _t('Failed to load playlists: $err', 'Gagal memuat playlist: $err');
  String get noPlaylistsForAccount => _t('No playlists could be loaded from this account.', 'Tidak ada playlist yang bisa dimuat dari akun ini.');
  String get playlistEmpty => _t('This playlist is empty', 'Playlist ini kosong');
  String get failedToLoadTracks => _t('Failed to load tracks', 'Gagal memuat lagu');
  String get connectionError => _t('Connection error. Check your network.', 'Kesalahan koneksi. Periksa jaringanmu.');
  String get disconnected => _t('disconnected', 'sudah dicopot');
  String get upNext => _t('Up next', 'Berikutnya');
  String get upNextSwipe => _t('Swipe a song to remove it from the queue', 'Geser lagu untuk membuangnya dari antrian');

  // Saved mixes
  String get savedMixes => _t('Saved mixes', 'Mix tersimpan');
  String get noSavedMixes => _t('No saved mixes yet.', 'Belum ada mix tersimpan.');
  String get deleteMixTitle => _t('Delete mix?', 'Hapus mix?');
  String deleteMixConfirm(String title) => _t('Delete "$title" from saved mixes?', 'Hapus "$title" dari mix tersimpan?');
  String get cancel => _t('Cancel', 'Batal');
  String get delete => _t('Delete', 'Hapus');
  String mixRemoved(String title) => _t('"$title" removed from saved mixes', '"$title" dihapus dari mix tersimpan');
  String get dynamicFromYoutube => _t('Dynamic from YouTube', 'Dinamis dari YouTube');
  String trackCount(int count) => _t('$count songs', '$count lagu');

  // Recommendations error
  String get serverOffline => _t('Cannot connect to server. Make sure the backend is running.', 'Tidak bisa terhubung ke server. Pastikan backend berjalan.');
  String get loadRecommendationsFailed => _t('Failed to load recommendations.', 'Gagal memuat rekomendasi.');
  String get tryAgain => _t('Try again', 'Coba lagi');
  String get noNewRecommendations => _t('No new recommendations available right now.', 'Tidak ada rekomendasi baru saat ini.');

  // Queue panel
  String get close => _t('Close', 'Tutup');
  String removedFromQueue(String title) => _t('Removed: $title', 'Dihapus: $title');
  String get undo => _t('Undo', 'Urungkan');

  // Account linking
  String accountLinked(String email) => _t('Account linked: $email', 'Akun tersambung: $email');

  // Player errors (displayed in UI layer)
  String get playbackError => _t('A playback error occurred', 'Terjadi kesalahan pemutaran');
  String get failedToLoadQueue => _t('Failed to load playback queue', 'Gagal memuat antrian audio');
  String get sourceNotPlayableYet => _t('This source cannot be played yet', 'Sumber ini belum bisa diputar');
}

final l10nProvider = Provider<L10n>((ref) => L10n(ref.watch(languageProvider)));
