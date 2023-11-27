import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../page_manager.dart';
import 'audio_file.dart';

class CloudRecordListView extends StatefulWidget {
  const CloudRecordListView({
    super.key,
  });

  @override
  State<CloudRecordListView> createState() => _CloudRecordListViewState();
}

class _CloudRecordListViewState extends State<CloudRecordListView> {
  var logger = Logger();
  late AudioPlayer audioPlayer;
  late SharedPreferences prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? selectedIndex = -1;
  String url = '';
  bool isPlaying = false;
  List<AudioFile> audioList = [];
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );

  Future<void> getAudioDatass() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('audioFiles').get();

      setState(() {
        audioList = querySnapshot.docs.map((doc) {
          return AudioFile.fromSnapshot(doc);
        }).toList();
      });
    } catch (error) {
      print('Error retrieving Datass: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    getAudioDatass();

    SharedPreferences.getInstance().then((sharedPrefs) {
      prefs = sharedPrefs;
    });

    audioPlayer.playerStateStream.listen((playerState) {
      final isPlayying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = ButtonState.loading;
      } else if (!isPlayying) {
        buttonNotifier.value = ButtonState.paused;
        // pause();
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = ButtonState.playing;
      } else {
        audioPlayer.seek(Duration.zero);
      }
    });

    audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });

    audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });

    audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }

  void seek(Duration position) {
    audioPlayer.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    if (audioList.isEmpty) {
      return const Center(
        child: Text("Empty"),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RefreshIndicator(
            onRefresh: () => getAudioDatass(),
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return const SizedBox(
                  height: 20,
                );
              },
              shrinkWrap: true,
              itemCount: audioList.length,
              reverse: true,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: ValueListenableBuilder<ProgressBarState>(
                    valueListenable: progressNotifier,
                    builder: (_, value, __) {
                      return buildProgressBar(value, index);
                    },
                  ),
                  trailing: SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: icon(index, audioList[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  ProgressBar buildProgressBar(ProgressBarState value, int index) {
    return selectedIndex == index
        ? ProgressBar(
            progress: value.current,
            buffered: value.buffered,
            total: value.total,
            progressBarColor: const Color(0xff36A0FC),
            bufferedBarColor: const Color(0xff36A0FC).withOpacity(0.5),
            thumbColor: const Color(0xff36A0FC),
            onSeek: seek,
          )
        : ProgressBar(
            progress: Duration.zero,
            buffered: Duration.zero,
            total: Duration.zero,
            progressBarColor: const Color(0xff36A0FC),
            bufferedBarColor: const Color(0xff36A0FC).withOpacity(0.5),
            thumbColor: const Color(0xff36A0FC),
            onSeek: seek,
          );
  }

  Widget icon(int index, AudioFile myModel) {
    if (selectedIndex == index) {
      return myModel.isPlaying == true
          ? IconButton(
              onPressed: () => iconButtonSelectedIndex(index, myModel),
              icon: const Center(child: Icon(Icons.pause)),
              iconSize: 30,
            )
          : IconButton(
              onPressed: () => iconButtonSelectedIndex(index, myModel),
              icon: const Center(child: Icon(Icons.play_arrow)),
              iconSize: 30,
            );
    } else {
      return IconButton(
        onPressed: () => retrieveRecentPlayInfo(index, myModel),
        icon: const Center(child: Icon(Icons.play_arrow)),
        iconSize: 30,
      );
    }
  }

  iconButtonSelectedIndex(int index, AudioFile myModel) async {
    selectedIndex = index;

    if (myModel.isPlaying == true) {
      pause(myModel);
    } else {
      retrieveRecentPlayInfo(index, myModel);
    }
  }



  Future<void> storeRecentPlayInfo(AudioFile myModel, Duration position) async {
    await prefs.setString('recentId', myModel.audioId ?? '');
    await prefs.setInt('recentDuration', position.inMilliseconds);
  }

  Future<void> retrieveRecentPlayInfo(int index, AudioFile myModel) async {
    final recentId = prefs.getString('recentId') ?? '';
    final recentDuration = prefs.getInt('recentDuration') ?? 0;
    selectedIndex = index;

    logger.d('Datass 1: $recentId');
    logger.d('Datass 2: $recentDuration');


    if (recentId == myModel.audioId) {
      logger.d('Datass 3:');
      final storedDuration = Duration(milliseconds: recentDuration);
      final storedUrl = myModel.downloadURL ?? '';
      await audioPlayer.setUrl(storedUrl);
      audioPlayer.seek(storedDuration);
      audioPlayer.play();
      myModel.isPlaying = true;
    } else {
      logger.d('Datass 4:');
      url = myModel.downloadURL ?? "";
      await audioPlayer.setUrl(url);
      audioPlayer.play();
      myModel.isPlaying = true;
    }
    setState(() {});
  }

  pause(AudioFile myModel) async {
    logger.d('Datass 5:');
    final position = audioPlayer.position;
    storeRecentPlayInfo(myModel, position);
    audioPlayer.stop();
    myModel.isPlaying = false;
    setState(() {});
  }
}
