import 'package:firebase_audio/recorder/play_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class CloudRecordListView extends StatefulWidget {
  final List<Reference> references;

  const CloudRecordListView({
    super.key,
    required this.references,
  });

  @override
  State<CloudRecordListView> createState() => _CloudRecordListViewState();
}

class _CloudRecordListViewState extends State<CloudRecordListView> {
  List<PlayModel> myModels = [];

  late AudioPlayer audioPlayer;
  String url = '';

  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    dataCollect();
    audioPlayer = AudioPlayer();
    selectedIndex = -1;
  }

  dataCollect() {
    myModels = widget.references.map((ref) {
      return PlayModel(name: ref.name, url: ref.fullPath);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
        stream: audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final processingState = snapshot.data?.processingState;
          return ListView.builder(
            itemCount: myModels.length,
            reverse: true,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(myModels[index].name ?? ""),
                trailing: SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: icon(index, myModels[index], processingState),
                  ),
                ),
              );
            },
          );
        });
  }

  Widget icon(int index, PlayModel myModel, ProcessingState? processingState) {
    if (selectedIndex == index) {
      if (processingState == ProcessingState.buffering ||
          processingState == ProcessingState.loading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else {
        return myModel.isPlaying == true
            ? IconButton(
                onPressed: () =>
                    iconButtonSelectedIndex(index, myModel, processingState),
                icon: const Center(child: Icon(Icons.pause)),
                iconSize: 30,
              )
            : IconButton(
                onPressed: () =>
                    iconButtonSelectedIndex(index, myModel, processingState),
                icon: const Center(child: Icon(Icons.play_arrow)),
                iconSize: 30,
              );
      }
    } else {
      return IconButton(
        onPressed: () => iconButton(index, myModel),
        icon: const Center(child: Icon(Icons.play_arrow)),
        iconSize: 30,
      );
    }
  }

  iconButtonSelectedIndex(
      int index, PlayModel myModel, ProcessingState? processingState) async {
    selectedIndex = index;

    // Condition Check IsPlaying Song Or Not
    if (myModel.isPlaying == true) {
      audioPlayer.stop();
      myModel.isPlaying = false;
    } else {
      // Logic Play Music
      url = await widget.references.elementAt(index).getDownloadURL();
      await audioPlayer.setUrl(url);
      audioPlayer.play();
      myModel.isPlaying = true;
    }
    setState(() {});
  }

  iconButton(int index, PlayModel myModel) async {
    selectedIndex = index;

    // Logic Play Music
    url = await widget.references.elementAt(index).getDownloadURL();
    await audioPlayer.setUrl(url);
    audioPlayer.play();
    myModel.isPlaying = true;
    setState(() {});
  }
}
