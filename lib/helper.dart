import 'dart:io';

import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// returns downloaded file path from url
Future<String> findFileLocation(String url) async {
  final hash = 'offline'; //url.hashCode.toString();
  final filePath = 'playlist.m3u8'; //getFilePath(url);
  final appDocDir = await getApplicationDocumentsDirectory();
  final file = File(p.join(appDocDir.path, hash, filePath));
  return file.absolute.path;
}

Future<String> findDFileLocation() async {
  final hash = 'offline'; //url.hashCode.toString();
  final filePath = 'playlist.m3u8'; //getFilePath(url);
  final appDocDir = await getApplicationDocumentsDirectory();
  final file = File(p.join(appDocDir.path, hash, filePath));
  return file.absolute.path;
}

String audioFilePath = '';
File audioFile;
File mainStreamFile;

/// takes a [url] and remove scheme, and last file part
///
/// for example, https://abc.com/a/b/c.m3u8
/// to
/// abc.com/a/b
String normalizeUrl(String url) {
  final uri = Uri.parse(url);
  final dir = p.join(
    uri.host,
    uri.pathSegments.sublist(0, uri.pathSegments.length - 1).join('/'),
  );

  return dir;
}

String stripFilePath(String url) {
  final uri = Uri.parse(url);
  final dir = p.join(
    uri.host,
    uri.pathSegments.sublist(0, uri.pathSegments.length - 1).join('/'),
  );
  return '${uri.scheme}://' + dir;
}

/// takes a [url] and returns last file path
///
/// for example, https://abc.com/a/b/c.m3u8
/// to
/// c.m3u8
String getFilePath(String url) {
  final uri = Uri.parse(url);

  return uri.pathSegments.last;
}

/// takes a file path and returns path that are not file
///
/// for example `a/b/c.m3u8` to `[a, b]`
List<String> pathSegments(String url) {
  final segments = url.split('/');
  return segments.sublist(0, segments.length - 1);
}

/// downloads a file from [url] to [filepath]/[filename]
Future<File> downloadFile(String url, String filepath, String filename) async {
  final client = http.Client();
  final req = await client.get(Uri.parse(url));
  final bytes = req.bodyBytes;
  final file = File('$filepath/${filename}');
  var ff = '';
  for (final f in pathSegments(filename)) {
    final d = Directory(p.join(filepath, f));
    filepath = filepath + '/' + f;
    if (!await d.exists()) {
      await d.create();
    }
  }

  if (!await file.exists()) {
    await file.create();
  }

  await file.writeAsBytes(bytes);
  return file;
}

Future<List<Segment>> getHlsMediaFiles(Uri uri, List<String> lines) async {
  var playList;

  try {
    playList = await HlsPlaylistParser.create().parse(uri, lines);
  } on ParserException catch (e) {
    print('HLS Parsing Error:');
    print(e);
  }

  if (playList is HlsMediaPlaylist) {
    print('MEDIA Playlist');
    return playList.segments;
  } else {
    return [];
  }
}

Future<Map> loadFileMetadata(String url) async {
  final uri = Uri.parse(url);
  final client = http.Client();
  final req = await client.get(url);
  final lines = req.body;

  var playList;

  try {
    playList = await HlsPlaylistParser.create().parseString(uri, lines);
  } on ParserException catch (_) {
    print('Unable to parse HLS playlist');
  }

  if (playList is HlsMediaPlaylist) {
    return {'default': url};
  } else if (playList is HlsMasterPlaylist) {
    Map<String, String> result = {};

    for (final p in playList.variants) {
      result['${p.format.height} x ${p.format.width}'] = p.url.toString();
    }

    for (final a in playList.audios) {
      var audioURI = a.url;
      final aFileName = getFilePath(audioURI.toString());
      final appDocDir = await getApplicationDocumentsDirectory();

      // directory to download files
      final downloadDir = Directory(p.join(
        appDocDir.path,
        'offline', // a hash of url
      ));

      if (!await downloadDir.exists()) {
        await downloadDir.create();
      }

      final filepath = p.join(downloadDir.path, aFileName);
      audioFile = File(filepath);
      if (!await audioFile.exists()) {
        audioFile =
            await downloadFile(a.url.toString(), downloadDir.path, aFileName);

        audioFilePath = a.url.toString();
      }
    }

    ///////
    final filename = getFilePath(url);

    // the app's directory to store data
    final appDocDir = await getApplicationDocumentsDirectory();

    // directory to download files
    final downloadDir = Directory(p.join(
      appDocDir.path,
      'offline', // a hash of url
    ));
    if (!await downloadDir.exists()) {
      await downloadDir.create();
    }
    final filepath = p.join(downloadDir.path, filename);
    var file = File(filepath);
    mainStreamFile = file;
    if (!await file.exists()) {
      file = await downloadFile(url, downloadDir.path, filename);
    }
    ///////////
    return result;
  } else {
    throw 'Unable to recognize HLS playlist type';
  }
}

/// download file from [url] and returns downloaded file path
Future<String> load(String url, Function(double) progress) async {
  // the file path without full url
  final filename = getFilePath(url);

  // the app's directory to store data
  final appDocDir = await getApplicationDocumentsDirectory();

  // directory to download files
  final downloadDir = Directory(p.join(
    appDocDir.path,
    'offline' /*url.hashCode.toString()*/, // a hash of url
  ));

  if (!await downloadDir.exists()) {
    await downloadDir.create();
  }

  // the full directory + filename path to download
  final filepath = p.join(downloadDir.path, filename);
  var file = File(filepath);
  if (await file.exists()) {
    file.deleteSync();
  }
  if (!await file.exists()) {
    file = await downloadFile(url, downloadDir.path, filename);
  }

  final lines = await file.readAsLines();
  var mediaSegments = await getHlsMediaFiles(Uri.parse(file.path), lines);

  final lines1 = await audioFile.readAsLines();

  final linesofStreamfile = await mainStreamFile.readAsLines();

  final filepath1 = p.join(downloadDir.path, 'playlist.m3u8');
  var filenew = File(filepath1);
  if (await filenew.exists()) {
    filenew.deleteSync();
  }
  if (!await filenew.exists()) {
    await filenew.create;
  }

  int spacecount = 0;
  int linecount = 0;
  for (final line in linesofStreamfile) {
    print(line);
    if (line == '') {
      spacecount++;
    }
    //await filenew.writeAsString(line);

    filenew.writeAsStringSync(line + '\n', mode: FileMode.append);

    if (spacecount == 2) {
      break;
    }
  }
  String linebefore = '';
  spacecount = 0;
  for (final line in linesofStreamfile) {
    print(line);

    if (line == '') {
      spacecount++;
    }

    if (spacecount == 2) {
      if (line.contains(filename)) {
        linebefore = linesofStreamfile[linecount - 1];
//        await filenew.writeAsString(linebefore);
//        await filenew.writeAsString(line);
        filenew.writeAsStringSync(linebefore + '\n', mode: FileMode.append);
        filenew.writeAsStringSync(line + '\n', mode: FileMode.append);
      }
    }
    linecount++;
  }

  var mediaSegments2 =
      await getHlsMediaFiles(Uri.parse(mainStreamFile.path), linesofStreamfile);

  var mediaSegments1 =
      await getHlsMediaFiles(Uri.parse(audioFile.path), lines1);

  for (final segment in mediaSegments1) {
    mediaSegments.add(segment);
  }

  final total = mediaSegments.length;
  var currentProgress = 0.0;

  print(total);

  for (final entry in mediaSegments.asMap().entries) {
    final index = entry.key;
    final seg = entry.value;

    // internet url to download from
    final urlToDownload = p.join(
      pathSegments(url).join('/'),
      seg.url,
    );

    // print('urlToDownload');
    // print(urlToDownload);

    // application's file to download into
    var ff = File(p.join(downloadDir.path, seg.url));

    if (!await ff.exists()) {
      await downloadFile(urlToDownload, downloadDir.path, seg.url);
    }

    if (index != total - 1) {
      // if not last
      currentProgress += double.parse(((1 / total) * 100).toStringAsFixed(2));
      await progress(currentProgress);
    } else {
      currentProgress = 100.0;
      await progress(currentProgress);
    }
  }
  print('downloaded at $file.absolute.path');

  return file.absolute.path;
}
