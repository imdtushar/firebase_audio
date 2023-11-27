import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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
  late AudioPlayer audioPlayer;
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

  Future<void> getAudioData() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('audioFiles').get();

      setState(() {
        audioList = querySnapshot.docs.map((doc) {
          return AudioFile.fromSnapshot(doc);
        }).toList();
      });
    } catch (error) {
      print('Error retrieving data: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    getAudioData();

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
        // pause();
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
            onRefresh: () => getAudioData(),
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
        onPressed: () => iconButton(index, myModel),
        icon: const Center(child: Icon(Icons.play_arrow)),
        iconSize: 30,
      );
    }
  }

  iconButtonSelectedIndex(int index, AudioFile myModel) async {
    selectedIndex = index;

    if (myModel.isPlaying == true) {
      audioPlayer.stop();
      myModel.isPlaying = false;
    } else {
      url = myModel.downloadURL ?? "";
      audioPlayer.setUrl(url);
      audioPlayer.play();
      myModel.isPlaying = true;
    }
    setState(() {});
  }

  iconButton(int index, AudioFile myModel) async {
    selectedIndex = index;

    url = myModel.downloadURL ?? "";
    await audioPlayer.setUrl(url);
    audioPlayer.play();
    myModel.isPlaying = true;
    setState(() {});
  }
}
