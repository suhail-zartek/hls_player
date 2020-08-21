import 'dart:io';

import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hlsofflineplayer/resolution_selection_dialogue.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typeweight/typeweight.dart';

import 'helper.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HLS Player',
    theme: ThemeData(
      primarySwatch: Colors.deepOrange,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
      home: VideoPlayerPage("https://player.vimeo.com/external/447746136.m3u8?s=d2c6f5a57ec59979b9d64487c32a66a1d35de92b"),
  ));
}

//class MyApp extends StatefulWidget {
//  // This widget is the root of your application.
//  @override
//  _MyAppState createState() => _MyAppState();
//}
//
//class _MyAppState extends State<MyApp> {
//  TextEditingController _controller;
//
//  FocusNode _focusNode;
//  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//
//  @override
//  void initState() {
//    // TODO: implement initState
//    super.initState();
//    _controller = TextEditingController();
//    _controller.text =
//        'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8';
//  }
//
//  @override
//  void dispose() {
//    _controller.dispose();
//    _focusNode.dispose();
//    super.dispose();
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      debugShowCheckedModeBanner: false,
//      title: 'Flutter Demo',
//      theme: ThemeData(
//        primarySwatch: Colors.deepOrange,
//        visualDensity: VisualDensity.adaptivePlatformDensity,
//      ),
////      home: VideoPlayerPage(
////          'https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8'),
////    );
//      home: Scaffold(
//        key: _scaffoldKey,
//        appBar: AppBar(
//          title: Text('Offline HLS Player'),
//        ),
//        body: Center(
//          child: Column(
//            mainAxisAlignment: MainAxisAlignment.center,
//            crossAxisAlignment: CrossAxisAlignment.center,
//            children: [
//              Padding(
//                padding: const EdgeInsets.all(
//                  NavigationToolbar.kMiddleSpacing,
//                ),
//                child: TextField(
//                  controller: _controller,
//                  focusNode: _focusNode,
//                ),
//              ),
//              SizedBox(
//                height: 20.0,
//              ),
//              Padding(
//                padding: const EdgeInsets.all(
//                  NavigationToolbar.kMiddleSpacing,
//                ),
//                child: RaisedButton(
//                  padding: const EdgeInsets.symmetric(
//                    vertical: NavigationToolbar.kMiddleSpacing / 1.5,
//                  ),
//                  elevation: 0,
//                  onPressed: () {
//                    if (_controller.text.isNotEmpty) {
//                      Navigator.of(context).push(MaterialPageRoute(
//                          builder: (context) =>
//                              VideoPlayerPage(_controller.text)));
//                    } else {
//                      _scaffoldKey.currentState.showSnackBar(SnackBar(
//                        content: Text('Enter your hls url!'),
//                        duration: Duration(seconds: 3),
//                      ));
//                    }
//                  },
//                  child: Text(
//                    'Play',
//                    style: GoogleFonts.ubuntuMono(
//                      fontWeight: TypeWeight.bold,
//                      fontSize: Theme.of(context).textTheme.headline6.fontSize,
//                    ),
//                  ),
//                ),
//              ),
//            ],
//          ),
//        ),
//      ),
//    );
//  }
//}

class VideoPlayerPage extends StatefulWidget {
  final String path;

  VideoPlayerPage(this.path);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  Future<void> _future;

  final FijkPlayer oplayer = FijkPlayer();
  String _currentSelectedResolutionFile;
  List<String> listResolution;
  List<String> listResolutionFileName;
  String _currentSelectedresolution;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String downloadProgress = '';
  bool isDownloaded = false;
  bool isPlayingOffline = false;

  @override
  void deactivate() {
    super.deactivate();
  }

  void initSharedPref() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> onRefresh() async {
    String dataSource = await findDFileLocation();
    await oplayer.reset();
    await oplayer.setDataSource(dataSource, autoPlay: true);
  }

  void _showResolutionSelectionDialog(qualities, fileNames) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    var changed = await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return ResolutionSelectionDialogue(
            listResolution: qualities,
            listResolutionFileName: fileNames,
            currentSelectedresolution:
                _currentSelectedresolution ?? listResolution[0]);
      },
    );

    if (changed != null) {
      _currentSelectedResolutionFile = changed;
      _currentSelectedresolution = listResolution[
          listResolutionFileName.indexOf(_currentSelectedResolutionFile)];
      print(_currentSelectedResolutionFile + 'selected');

      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(
            'Download started for Resolution : $_currentSelectedresolution'),
        duration: Duration(seconds: 3),
      ));

      await load(_currentSelectedResolutionFile, (progress) async {
        print("Download progress: $progress");
        setState(() {
          downloadProgress = '${progress.toStringAsFixed(1)}%';

          if (progress >= 100) {
            downloadProgress = '';
            isDownloaded = true;

            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Download completed'),
              duration: Duration(seconds: 3),
            ));
          }
        });
        //       print('finished download queue');
      });
    }
  }

  void startPlay() async {
    await oplayer.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    await oplayer.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    await oplayer.setOption(2, 'BANDWIDTH', '10285391');
    oplayer.setDataSource(widget.path, autoPlay: true);
  }

  void ostartPlay() async {
    await oplayer.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    await oplayer.setOption(FijkOption.hostCategory, "request-audio-focus", 1);

    String opath = await findDFileLocation();
    print(opath);
    await oplayer.reset();

    oplayer.setDataSource(opath, autoPlay: true);
  }

  @override
  void initState() {
    super.initState();
    initSharedPref();

    startPlay();
  }

  @override
  void dispose() {
    super.dispose();

    oplayer.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      //appBar: AppBar(title: Text("Player")),
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            child: FijkView(
              player: oplayer,

//                    panelBuilder: fijkPanel2Builder(snapShot: true),
              fit: FijkFit.fitWidth,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20, right: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                !isDownloaded
                    ? Text(
                        '',
                        style: TextStyle(
                            color: Colors.deepOrange.shade400, fontSize: 20),
                      )
                    : Container(
                        //padding: EdgeInsets.all(20),
                        height: 50.0,
                        width: 50.0,
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.deepOrange.shade400,
                            size: 40,
                          ),
                          onPressed: () async {
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text('File deleted'),
                              duration: Duration(seconds: 3),
                            ));

                            setState(() {
                              isDownloaded = false;
                              downloadProgress = '';
                            });
                            oplayer.reset();
                            startPlay();
                            final appDocDir =
                                await getApplicationDocumentsDirectory();

                            await Directory(
                                    normalizeUrl(appDocDir.path + 'offline'))
                                .delete(recursive: true);

                            await Directory(
                                    normalizeUrl(appDocDir.path + 'audio'))
                                .delete(recursive: true);

                            await Directory(
                                    normalizeUrl(appDocDir.path + 'video'))
                                .delete(recursive: true);

                            //initState();
                          },
                        ),
                      ),
                SizedBox(
                  width: 20,
                ),
                !isDownloaded
                    ? Text(
                        downloadProgress,
                        style: TextStyle(
                            color: Colors.deepOrange.shade400, fontSize: 20),
                      )
                    : Container(
                        //padding: EdgeInsets.all(20),
                        height: 50.0,
                        width: 50.0,
                        child: IconButton(
                          icon: Icon(
                            isPlayingOffline
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.deepOrange.shade400,
                            size: 40,
                          ),
                          onPressed: () async {
                            setState(() {
                              isPlayingOffline = true;

                              ostartPlay();
                            });
                          },
                        ),
                      ),
                SizedBox(
                  width: 20,
                ),
                Container(
                  //padding: EdgeInsets.all(20),
                  height: 50.0,
                  width: 50.0,
                  child: IconButton(
                    icon: Icon(
                      Icons.save_alt,
                      size: 40,
                      color: Colors.deepOrange.shade400,
                    ),
                    onPressed: () async {
                      final url = widget.path;
                      try {
                        final q = await loadFileMetadata(url);
                        setState(() {
                          listResolution = q.keys.toList();
                          listResolutionFileName = q.values.toList();
                          _showResolutionSelectionDialog(
                              listResolution, listResolutionFileName);
                        });
                      } catch (e) {
                        print(e);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
