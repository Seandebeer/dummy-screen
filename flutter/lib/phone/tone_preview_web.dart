import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart';

HTMLAudioElement? _playing;

/// Plays the uploaded clip, or a short tone named like the built-in sound.
void previewTone({required String name, required String custom}) {
  _playing?.pause();
  final src = name == 'Custom' && custom.startsWith('data:audio') ? custom : _tone(name);
  final audio = HTMLAudioElement();
  audio.src = src;
  audio.volume = 1;
  document.body?.appendChild(audio);
  audio.play();
  _playing = audio;
}

String _tone(String name) {
  const pitches = {
    'Reflection': 392.0,
    'Opening': 440.0,
    'Apex': 494.0,
    'Ripple': 523.0,
    'Pulse': 587.0,
    'Classic': 659.0,
    'Marimba': 698.0,
    'Alarm': 880.0,
  };
  return _wav(pitches[name] ?? 440);
}

String _wav(double freq) {
  const rate = 22050;
  const count = 12000;
  final data = Uint8List(count * 2);
  final samples = ByteData.sublistView(data);
  for (var i = 0; i < count; i++) {
    final attack = (i / 400).clamp(0.0, 1.0);
    final release = ((count - i) / 3000).clamp(0.0, 1.0);
    final tone = math.sin(2 * math.pi * freq * i / rate);
    final fifth = 0.35 * math.sin(2 * math.pi * freq * 1.5 * i / rate);
    final sample = (tone + fifth) * attack * release;
    samples.setInt16(i * 2, (sample * 16000).round().clamp(-32767, 32767), Endian.little);
  }
  final bytes = Uint8List(44 + data.length);
  final header = ByteData.sublistView(bytes, 0, 44);
  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  header.setUint32(4, 36 + data.length, Endian.little);
  bytes.setRange(8, 12, 'WAVE'.codeUnits);
  bytes.setRange(12, 16, 'fmt '.codeUnits);
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, rate, Endian.little);
  header.setUint32(28, rate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, 'data'.codeUnits);
  header.setUint32(40, data.length, Endian.little);
  bytes.setRange(44, bytes.length, data);
  return 'data:audio/wav;base64,${base64Encode(bytes)}';
}
