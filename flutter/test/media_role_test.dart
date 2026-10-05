import 'package:dummy_phone/media/signal_hub.dart';
import 'package:dummy_phone/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deck mic stays here unless this machine only joined', () {
    expect(controlMediaHere('solo'), isTrue);
    expect(controlMediaHere('host'), isTrue);
    expect(controlMediaHere('client'), isFalse);
  });

  test('the phone peer runs on the joined machine', () {
    expect(phoneMediaHere('solo', 0), isTrue);
    expect(phoneMediaHere('host', 0), isTrue);
    expect(phoneMediaHere('host', 1), isFalse);
    expect(phoneMediaHere('client', 0), isTrue);
  });

  test('older call snapshots stay voice calls', () {
    final call = LiveCall.fromJson({
      'id': 'c1',
      'deviceId': 'd',
      'contactName': 'A',
      'contactNumber': '1',
      'direction': 'incoming',
      'status': 'ringing',
    });
    expect(call.kind, 'voice');
    const video = LiveCall(
      id: 'c2',
      deviceId: 'd',
      contactName: 'A',
      contactNumber: '1',
      direction: 'incoming',
      status: 'ringing',
      kind: 'video',
    );
    expect(LiveCall.fromJson(video.toJson()).kind, 'video');
    expect(video.copyWith(status: 'active').kind, 'video');
    expect(video.liveCamera, isTrue);
    final vfx = LiveCall.fromJson({
      ...video.toJson(),
      'scene': {'mode': 'vfx', 'bg': '#0047BB', 'mark': 'circles'},
    });
    expect(vfx.sceneMode, 'vfx');
    expect(vfx.liveCamera, isFalse);
    expect(vfx.copyWith(status: 'active').scene['mark'], 'circles');
  });

  test('a photo keeps its captured frame', () {
    const photo = PropPhoto(
      id: 'ph',
      color: 0xFF318DF6,
      createdAt: 1,
      image: 'data:image/png;base64,aa',
    );
    expect(PropPhoto.fromJson(photo.toJson()).image, photo.image);
    expect(
      PropPhoto.fromJson({'id': 'ph', 'color': 1, 'createdAt': 1}).image,
      '',
    );
  });
}
