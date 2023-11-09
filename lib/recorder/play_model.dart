import 'dart:convert';

/// name : "Song Name"
/// url : "https://www.example.com/song.mp3"
/// isPlaying : true

PlayModel playModelFromJson(String str) => PlayModel.fromJson(json.decode(str));

String playModelToJson(PlayModel data) => json.encode(data.toJson());

class PlayModel {
  PlayModel({
    this.name,
    this.url,
    this.isPlaying,
  });

  PlayModel.fromJson(dynamic json) {
    name = json['name'];
    url = json['url'];
    isPlaying = json['isPlaying'];
  }

  String? name;
  String? url;
  bool? isPlaying;

  PlayModel copyWith({
    String? name,
    String? url,
    bool? isPlaying,
  }) =>
      PlayModel(
        name: name ?? this.name,
        url: url ?? this.url,
        isPlaying: isPlaying ?? this.isPlaying,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['url'] = url;
    map['isPlaying'] = isPlaying;
    return map;
  }
}
