import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_audio/recorder/cloud_record_list_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';
  bool _isUploading = false;
  List<Reference> references = [];
  bool isPLaying = false;

  @override
  initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    _onUploadComplete();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

// Start Recording
  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        Directory directory = await getApplicationDocumentsDirectory();
        String filepath =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4a';
        await audioRecord.start(path: filepath);
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error Start  Recording : $e');
      }
    }
  }

  // Stop Recording
  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
        if (kDebugMode) {
          print("Audio Path $audioPath");
        }
        _onFileUploadButtonPressed(context);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error Stopping  Record : $e');
      }
    }
  }

  // Play Recording
  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      if (kDebugMode) {
        print("Url Maker $urlSource");
      }
      await audioPlayer.play(urlSource);
    } catch (e) {
      if (kDebugMode) {
        print('Error Stopping  Record : $e');
      }
    }
  }

// Upload Audio Firebase
  Future<void> _onFileUploadButtonPressed(context) async {
    FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    setState(() {
      _isUploading = true;
    });
    try {
      await firebaseStorage
          .ref('upload-voice-firebase')
          .child(
              audioPath.substring(audioPath.lastIndexOf('/'), audioPath.length))
          .putFile(File(audioPath));
    } catch (error) {
      if (kDebugMode) {
        print('Error occured while uplaoding to Firebase ${error.toString()}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occured while uplaoding'),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
      _onUploadComplete();
    }
  }

  // Get Audio List From Firebase
  Future<void> _onUploadComplete() async {
    FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    ListResult listResult =
        await firebaseStorage.ref().child('upload-voice-firebase').list();
    setState(() {
      references = listResult.items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isUploading
            ? const Center(
                child: Text('File Uploading'),
              )
            : Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Audio Player",
                        style: TextStyle(
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Flexible(
                    flex: 2,
                    child: Column(
                      children: [
                        if (isRecording)
                          const Text(
                            'Recording in Progress',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ElevatedButton(
                          onPressed:
                              isRecording ? stopRecording : startRecording,
                          child: isRecording
                              ? const Text("Stop Recording")
                              : const Text("Start Recording"),
                        ),
                        // const SizedBox(
                        //   height: 25,
                        // ),
                        // if (!isRecording && audioPath.isNotEmpty)
                        //   ElevatedButton(
                        //     onPressed: playRecording,
                        //     child: const Text('Pay Recording'),
                        //   ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    child: references.isEmpty
                        ? const Center(
                            child: Text('No File uploaded yet'),
                          )
                        : CloudRecordListView(
                            references: references,
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
