enum TrackSource {
  youtube('youtube', 'YT'),
  ytmusic('ytmusic', 'YTM'),
  soundcloud('soundcloud', 'SC'),
  spotify('spotify', 'SP');

  const TrackSource(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TrackSource fromApi(String raw) => TrackSource.values.firstWhere(
        (s) => s.apiValue == raw,
        orElse: () => TrackSource.youtube,
      );

  bool get playable => this == TrackSource.youtube || this == TrackSource.ytmusic;
}

enum PlaybackRepeat { off, all, one }

class Track {
  const Track({
    required this.id,
    required this.source,
    required this.title,
    this.artist = '',
    this.durationSeconds = 0,
    this.thumb = '',
    this.uploader = '',
    this.url = '',
  });

  final String id;
  final TrackSource source;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumb;
  final String uploader;
  final String url;

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String? ?? '',
        source: TrackSource.fromApi(json['source'] as String? ?? ''),
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
        thumb: json['thumb'] as String? ?? '',
        uploader: json['uploader'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  String get durationLabel {
    if (durationSeconds <= 0) return '';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class StreamInfo {
  const StreamInfo({required this.url, this.title = '', this.ext = '', this.abr});

  factory StreamInfo.fromJson(Map<String, dynamic> json) => StreamInfo(
        url: json['url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        ext: json['ext'] as String? ?? '',
        abr: (json['abr'] as num?)?.toDouble(),
      );

  final String url;
  final String title;
  final String ext;
  final double? abr;
}

class LyricsResult {
  const LyricsResult({required this.found, this.synced = false, this.plain, this.lrc});

  factory LyricsResult.fromJson(Map<String, dynamic> json) => LyricsResult(
        found: json['found'] as bool? ?? false,
        synced: json['synced'] as bool? ?? false,
        plain: json['plain'] as String?,
        lrc: json['lrc'] as String?,
      );

  final bool found;
  final bool synced;
  final String? plain;
  final String? lrc;
}

class YoutubeAccount {
  const YoutubeAccount({
    required this.email,
    required this.channelId,
    required this.channelTitle,
    required this.avatarUrl,
  });

  factory YoutubeAccount.fromJson(Map<String, dynamic> json) => YoutubeAccount(
        email: json['email'] as String? ?? '',
        channelId: json['channel_id'] as String? ?? '',
        channelTitle: json['channel_title'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
      );

  final String email;
  final String channelId;
  final String channelTitle;
  final String avatarUrl;

  String get displayName => channelTitle.isNotEmpty ? channelTitle : email;
}

class YoutubePlaylist {
  const YoutubePlaylist({
    required this.id,
    required this.title,
    required this.count,
    required this.thumb,
    required this.owner,
  });

  factory YoutubePlaylist.fromJson(Map<String, dynamic> json) => YoutubePlaylist(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        thumb: json['thumb'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
      );

  final String id;
  final String title;
  final int count;
  final String thumb;
  final String owner;
}