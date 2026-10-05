# Dummy Screen

Prop phone and control deck for iOS, Android, Windows, and macOS. One Flutter project; each platform builds from this folder.

On a phone, open **OS** and mark that device as this phone. On the operator machine, open **Control**, choose the device, and host the deck. Join from the phone with the address shown. Both machines need the same Wi-Fi.

## Run

Install Flutter, then from this directory:

```bash
flutter pub get
flutter run
```

| Platform | Build |
|---|---|
| iPhone / iPad | `flutter build ios` and open `ios/Runner.xcworkspace` in Xcode |
| Mac | `flutter build macos` and open `macos/Runner.xcworkspace` in Xcode |
| Android | `flutter build apk` |
| Windows | `flutter build windows` on a Windows machine |

iOS and macOS have to be compiled on a Mac. Windows has to be compiled on Windows. Camera, microphone, photo library, and local network use are declared for the prop camera and the deck link.
