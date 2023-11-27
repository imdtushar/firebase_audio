import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_audio/recorder/cloud_record_list_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

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
  bool isPLaying = false;

  @override
  initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();
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
        _onFileUploadButtonPressed(context, audioPath);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error Stopping  Record : $e');
      }
    }
  }

  // bool _isUploading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload Audio Firebase
  Future<void> _onFileUploadButtonPressed(context, String audioPath) async {
    FirebaseStorage firebaseStorage = FirebaseStorage.instance;
    String generateRandomId() {
      // Using the UUID package to generate a random ID
      var uuid = const Uuid();
      return uuid.v4(); // Generating a version 4 (random) UUID
    }

    setState(() {
      _isUploading = true;
    });
    try {
      TaskSnapshot uploadTask = await firebaseStorage
          .ref('upload-voice-firebase')
          .child(
              audioPath.substring(audioPath.lastIndexOf('/'), audioPath.length))
          .putFile(File(audioPath));

      String downloadURL = await uploadTask.ref.getDownloadURL();

      String randomId = generateRandomId();

      await _firestore.collection('audioFiles').doc(randomId).set({
        'downloadURL': downloadURL,
        'audio_id': randomId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded successfully'),
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        print('Error occurred while uploading to Firebase ${error.toString()}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while uploading'),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

// // Upload Audio Firebase
//   Future<void> _onFileUploadButtonPressed(context) async {
//     FirebaseStorage firebaseStorage = FirebaseStorage.instance;
//     setState(() {
//       _isUploading = true;
//     });
//     try {
//       await firebaseStorage
//           .ref('upload-voice-firebase')
//           .child(
//               audioPath.substring(audioPath.lastIndexOf('/'), audioPath.length))
//           .putFile(File(audioPath));
//     } catch (error) {
//       if (kDebugMode) {
//         print('Error occured while uplaoding to Firebase ${error.toString()}');
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Error occured while uplaoding'),
//         ),
//       );
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//       _onUploadComplete();
//     }
//   }
//
//   // Get Audio List From Firebase
//   Future<void> _onUploadComplete() async {
//     FirebaseStorage firebaseStorage = FirebaseStorage.instance;
//     ListResult listResult =
//         await firebaseStorage.ref().child('upload-voice-firebase').list();
//     setState(() {
//       references = listResult.items;
//     });
//   }

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
                  const Flexible(
                    flex: 4,
                    child: CloudRecordListView(),
                  ),
                ],
              ),
      ),
    );
  }
}
