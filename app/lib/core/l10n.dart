import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<String> {
  static const _key = 'locale';

  @override
  String build() {
    _load();
    return 'en';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved != state) state = saved;
  }

  Future<void> toggle() async {
    final next = state == 'en' ? 'id' : 'en';
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next);
  }
}

class L10n {
  final String locale;
  L10n(this.locale);

  bool get isEn => locale != 'id';

  String _t(String en, String id) => isEn ? en : id;

  // Tabs & home
  String get forYou => _t('For You', 'Untukmu');
  String get greetingBack =>
      _t('Pick up where you left off', 'Lanjutkan dari tempat kamu berhenti');
  String get recentlyPlayed => _t('Recently played', 'Baru diputar');
  String get search => _t('Search', 'Cari');
  String get queue => _t('Queue', 'Antrian');
  String get playlist => _t('Playlist', 'Playlist');
  String get changeTheme => _t('Change theme', 'Ganti tema');
  String get changeLanguage => _t('Language', 'Ganti bahasa');

  // Search
  String get searchHint => _t('Search songs, artists…', 'Cari lagu, artis…');
  String get searchFailed => _t('Search failed', 'Gagal mencari');
  String get searchLoading => _t('Searching…', 'Mencari…');
  String get searchRetry => _t(
    'Try another keyword or change the source.',
    'Coba kata kunci lain atau ubah sumber pencarian.',
  );
  String get appBuildRejected => _t(
    'The server rejected this app build. Install the newest version and try again.',
    'Server menolak versi aplikasi ini. Pasang versi terbaru lalu coba lagi.',
  );
  String get serverUnreachable => _t(
    'Cannot reach the server. Check your connection.',
    'Tidak bisa menghubungi server. Periksa koneksimu.',
  );
  String get serverBusy => _t(
    'The server had a problem. Try again in a moment.',
    'Server sedang bermasalah. Coba lagi sebentar lagi.',
  );
  String get searchEmpty => _t(
    'Type to search. Recent searches appear here.',
    'Ketik untuk mencari. Pencarian terbaru muncul di sini.',
  );
  String get searchNoResults => _t('No results', 'Tidak ada hasil');
  String get searchStartHere => _t('Start here', 'Mulai dari sini');
  String get searchHistoryLabel => _t('Search history', 'Riwayat pencarian');
  String get searchSuggestionsLabel => _t('Suggestions', 'Saran');
  String get useThisQuery => _t('Use this search', 'Pakai pencarian ini');
  String get mixLabel => _t('Mix', 'Mix');
  String get mixSubtitle => _t(
    'Radio from YouTube Music',
    'Radio dari YouTube Music',
  );
  String get mixUntitled => _t('YouTube Music mix', 'Mix YouTube Music');
  String get mixLoadFailed =>
      _t('Could not load this mix', 'Gagal memuat mix ini');
  String get mixBadge => _t('Mix', 'Mix');
  String get searchPlanLabel => _t('Search history', 'Riwayat pencarian');
  String get searchClear => _t('Clear', 'Bersihkan');
  String searchResults(int count) => _t('$count results', '$count hasil');
  String get playAll => _t('Play all', 'Putar semua');
  String get moreActions => _t('More actions', 'Aksi lain');
  String get playNow => _t('Play now', 'Putar sekarang');
  String get playNext => _t('Play next', 'Putar berikutnya');
  String get addToQueue => _t('Add to queue', 'Tambahkan ke antrian');
  String get addToQueueShort => _t('Add to queue', 'Tambah ke antrian');
  String get addToPlaylist => _t('Add to playlist', 'Tambah ke playlist');
  String get removeFromPlaylist =>
      _t('Remove from playlist', 'Hapus dari playlist');

  // Queue
  String get queueEmptyTitle => _t('Queue is empty', 'Antrian kosong');
  String get queueEmptySubtitle => _t(
    'Search a song then tap the add button, or play straight from results.',
    'Cari lagu lalu tekan tombol tambah, atau langsung mainkan dari hasil pencarian.',
  );
  String queueCount(int count) => _t('QUEUE · $count', 'ANTRIAN · $count');
  String get clearQueue => _t('Clear queue', 'Kosongkan antrian');
  String get clearQueueTitle => _t('Clear queue?', 'Kosongkan antrian?');
  String get clearQueueConfirm => _t(
    'Every song currently in the queue will be removed.',
    'Semua lagu di antrian akan dihapus.',
  );
  String get upNextShort => _t('Up next', 'Berikutnya');
  String get removeFromQueueShort =>
      _t('Remove from queue', 'Hapus dari antrian');

  // Player / NowPlaying
  String get nowPlaying => _t('Now playing', 'Sedang diputar');
  String get lyrics => _t('Lyrics', 'Lirik');
  String get noPlayer => _t('Nothing playing yet', 'Belum ada yang diputar');
  String get playError =>
      _t('A playback error occurred', 'Terjadi kesalahan pemutaran');
  String get loadQueueError =>
      _t('Failed to load playback queue', 'Gagal memuat antrian audio');
  String get sourceNotPlayable =>
      _t('This source cannot be played yet', 'Sumber ini belum bisa diputar');
  String trackLoadFailed(String title) =>
      _t('Could not load "$title"', 'Gagal memuat "$title"');
  String get queueLoadFailed =>
      _t('Could not load the queue', 'Gagal memuat antrian');
  String get trackNotPlayable =>
      _t('This source cannot be played yet', 'Sumber ini belum bisa diputar');
  String get downloadSavedForOffline =>
      _t('saved for offline', 'tersimpan untuk offline');
  String get downloadFailed => _t('Download failed', 'Unduhan gagal');
  String get downloadRemoved => _t('Download removed', 'Unduhan dihapus');
  String get removeDownload => _t('Remove download', 'Hapus unduhan');
  String get saveForOffline => _t('Save for offline', 'Simpan untuk offline');

  // Repeat
  String get repeatAll => _t('Repeat all', 'Ulang semua');
  String get repeatOne => _t('Repeat one', 'Ulang satu');
  String get repeatOff => _t('No repeat', 'Tanpa ulang');

  // Lyrics
  String lyricsTitle(String title) => _t('Lyrics: $title', 'Lirik: $title');
  String get lyricsLoading => _t('Loading lyrics…', 'Memuat lirik…');
  String get lyricsNotFound =>
      _t('Lyrics not found.', 'Lirik tidak ditemukan.');
  String get lyricsNotInDb => _t(
    'The lyrics database does not have this song.',
    'DB lirik tidak punya lagu ini.',
  );

  // For You / Accounts
  String get noHistory =>
      _t('No playback history yet', 'Belum ada riwayat putar');
  String get topPlayed => _t('Top played', 'Paling sering');
  String get recentlyPlayedTitle => _t('Recently played', 'Baru-baru ini');
  String topSubtitle(int count) =>
      _t('$count songs · from your history', '$count lagu · dari riwayatmu');
  String recentSubtitle(int count) =>
      _t('$count songs · continue', '$count lagu · lanjutkan');
  String get recommendedForYou =>
      _t('Recommended for you', 'Direkomendasikan untukmu');
  String get accountsLabel => _t('YouTube accounts', 'Akun YouTube');
  String get playlistsUnavailable => _t(
    'Playlists could not be loaded right now.',
    'Playlist tidak bisa dimuat saat ini.',
  );
  String get noPlaylists => _t('No playlists', 'Tidak ada playlist');
  String get noAccounts => _t('No YouTube accounts', 'Belum ada akun YouTube');
  String get addAccount => _t('Add account', 'Tambah akun');
  String get removeActiveAccount =>
      _t('Remove active account', 'Copot akun aktif');
  String get yours => _t('Yours', 'Punya saya');
  String get likedPlaylists =>
      _t('Liked playlists', 'Playlist & video disukai');
  String get cantOpenBrowser =>
      _t('Cannot open browser', 'Tidak bisa membuka browser');
  String get accountsNotConfigured => _t(
    'This feature is not configured on the server',
    'Fitur akun belum dikonfigurasi di server',
  );
  String get playlistFromSelected => _t(
    'Playlists are shown from the account selected above.',
    'Playlist tampil dari akun yang dipilih di atas.',
  );
  String get connectYouTube =>
      _t('Connect YouTube account', 'Hubungkan akun YouTube');
  String get connectYouTubeSubtitle => _t(
    'View and play playlists and liked videos from your account.',
    'Lihat dan putar playlist serta video yang disukai dari akunmu.',
  );
  String get login => _t('Login', 'Login');
  String get noPlaylistsForAccount => _t(
    'No playlists could be loaded from this account.',
    'Tidak ada playlist yang bisa dimuat dari akun ini.',
  );
  String get playlistEmpty =>
      _t('This playlist is empty', 'Playlist ini kosong');
  String get failedToLoadTracks =>
      _t('Failed to load tracks', 'Gagal memuat lagu');
  String get connectionError => _t(
    'Connection error. Check your network.',
    'Kesalahan koneksi. Periksa jaringanmu.',
  );
  String get disconnected => _t('disconnected', 'sudah dicopot');
  String get upNext => _t('Up next', 'Berikutnya');
  String get upNextSwipe => _t(
    'Swipe a song to remove it from the queue',
    'Geser lagu untuk membuangnya dari antrian',
  );

  // Saved mixes
  String get savedMixes => _t('Saved mixes', 'Mix tersimpan');
  String get noSavedMixes =>
      _t('No saved mixes yet.', 'Belum ada mix tersimpan.');
  String get deleteMixTitle => _t('Delete mix?', 'Hapus mix?');
  String deleteMixConfirm(String title) => _t(
    'Delete "$title" from saved mixes?',
    'Hapus "$title" dari mix tersimpan?',
  );
  String get cancel => _t('Cancel', 'Batal');
  String get delete => _t('Delete', 'Hapus');
  String mixRemoved(String title) => _t(
    '"$title" removed from saved mixes',
    '"$title" dihapus dari mix tersimpan',
  );
  String get dynamicFromYoutube =>
      _t('Dynamic from YouTube', 'Dinamis dari YouTube');
  String get mixNotPlayableYet => _t(
    'Saving only for now. Playing is not ready yet.',
    'Baru disimpan. Memutar belum tersedia.',
  );
  String trackCount(int count) => _t('$count songs', '$count lagu');

  // Recommendations error
  String get serverOffline => _t(
    'Cannot connect to server. Make sure the backend is running.',
    'Tidak bisa terhubung ke server. Pastikan backend berjalan.',
  );
  String get loadRecommendationsLoading =>
      _t('Loading recommendations…', 'Menyusun rekomendasi…');
  String get loadRecommendationsFailed =>
      _t('Failed to load recommendations.', 'Gagal memuat rekomendasi.');
  String get tryAgain => _t('Try again', 'Coba lagi');
  String get noNewRecommendations => _t(
    'No new recommendations available right now.',
    'Tidak ada rekomendasi baru saat ini.',
  );

  // Queue panel
  String get close => _t('Close', 'Tutup');
  String removedFromQueue(String title) =>
      _t('Removed: $title', 'Dihapus: $title');
  String get undo => _t('Undo', 'Urungkan');

  // Account linking
  String accountLinked(String email) =>
      _t('Account linked: $email', 'Akun tersambung: $email');

  // Local playlists (offline)
  String get emptyPlaylistsTitle =>
      _t('No playlists yet', 'Belum ada playlist');
  String get emptyPlaylistsSubtitle => _t(
    'Build your own playlists that live on this device. Use "New playlist" above to start.',
    'Buat playlist sendiri yang tersimpan di perangkat ini. Tekan "Playlist baru" di atas untuk mulai.',
  );
  String get playlistSubtitle =>
      _t('Stored on this device', 'Tersimpan di perangkat ini');
  String get newPlaylist => _t('New playlist', 'Playlist baru');
  String get playlistName => _t('Playlist name', 'Nama playlist');
  String get playlistNameHint => _t('e.g. Road trip', 'mis. Perjalanan');
  String get playlistEmptyName =>
      _t('Give the playlist a name', 'Beri nama playlist dulu');
  String get createPlaylistTitle => _t('Create playlist', 'Buat playlist');
  String get create => _t('Create', 'Buat');
  String get rename => _t('Rename', 'Ganti nama');
  String get save => _t('Save', 'Simpan');
  String get renamePlaylistTitle =>
      _t('Rename playlist', 'Ganti nama playlist');
  String get deletePlaylistTitle => _t('Delete playlist?', 'Hapus playlist?');
  String deletePlaylistConfirm(String name) => _t(
    '"$name" and its songs will be deleted from this device.',
    '"$name" beserta lagunya akan dihapus dari perangkat ini.',
  );
  String get playlistDeleted => _t('Playlist deleted', 'Playlist dihapus');
  String get playlistRenamed => _t('Playlist renamed', 'Nama playlist diganti');
  String get playlistCreated => _t('Playlist created', 'Playlist dibuat');
  String get loadPlaylistsFailed =>
      _t('Could not load playlists', 'Gagal memuat playlist');
  String get loadPlaylistHint => _t(
    'Check your connection and try again.',
    'Periksa koneksi lalu coba lagi.',
  );
  String get loadPlaylistsLoading =>
      _t('Loading playlists…', 'Memuat playlist…');
  String get loadSongsLoading => _t('Loading songs…', 'Memuat lagu…');
  String get playAllLabel => _t('Play', 'Putar');
  String get shuffleLabel => _t('Shuffle', 'Acak');
  String get shufflePlay => _t('Shuffle play', 'Putar acak');
  String get noSongsTitle =>
      _t('This playlist is empty', 'Playlist ini kosong');
  String get noSongsSubtitle => _t(
    'Open any song menu and choose "Add to playlist".',
    'Buka menu lagu mana pun lalu pilih "Tambah ke playlist".',
  );
  String get removedFromPlaylist =>
      _t('Removed from playlist', 'Dihapus dari playlist');
  String get pickPlaylistTitle => _t('Add to playlist', 'Tambah ke playlist');
  String get pickPlaylistEmpty => _t(
    'Create a playlist first, then add songs to it.',
    'Buat playlist dulu, lalu masukkan lagu ke dalamnya.',
  );
  String addedToPlaylist(String name) =>
      _t('Added to "$name"', 'Ditambahkan ke "$name"');
  String get alreadyInPlaylists => _t('Already added', 'Sudah ada');
  String get reorderHint =>
      _t('Hold and drag to reorder', 'Tahan lalu geser untuk menyusun ulang');
}

final l10nProvider = Provider<L10n>((ref) => L10n(ref.watch(languageProvider)));
