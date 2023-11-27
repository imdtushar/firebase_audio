import 'package:cloud_firestore/cloud_firestore.dart';

class AudioFile {
  String? audioId;
  String? downloadURL;
  bool? isPlaying;

  AudioFile({this.audioId, this.downloadURL, this.isPlaying});

  factory AudioFile.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return AudioFile(
      audioId: snapshot.id,
      downloadURL: data['downloadURL'] ?? '',
      isPlaying: data['isPlaying'],
    );
  }
}
