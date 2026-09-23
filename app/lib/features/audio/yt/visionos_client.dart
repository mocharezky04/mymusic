import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _visionosUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15';

const visionosClient = YoutubeApiClient(
  {
    'context': {
      'client': {
        'clientName': 'VISIONOS',
        'clientVersion': '1.02',
        'deviceMake': 'Apple',
        'deviceModel': 'RealityDevice17,1',
        'userAgent': _visionosUserAgent,
        'osName': 'visionOS',
        'osVersion': '26.5.23O471',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
    'contentCheckOk': true,
    'racyCheckOk': true,
  },
  'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
  headers: {
    'X-Youtube-Client-Name': '101',
    'X-Youtube-Client-Version': '1.02',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-us,en;q=0.5',
    'Sec-Fetch-Mode': 'navigate',
    'Content-Type': 'application/json',
    'Origin': 'https://www.youtube.com',
  },
);