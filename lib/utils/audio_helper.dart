import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class AudioHelper {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  AudioHelper() {
    _player.openPlayer();
  }

  Future<void> playBase64(String base64) async {
    if (_player.isPlaying) await _player.stopPlayer();
    final bytes = base64Decode(base64);
    await _player.startPlayer(
      fromDataBuffer: Uint8List.fromList(bytes),
      codec: Codec.aacADTS,
      whenFinished: () {},
    );
  }

  Future<void> stop() async {
    if (_player.isPlaying) await _player.stopPlayer();
  }

  void dispose() {
    _player.closePlayer();
  }
}
