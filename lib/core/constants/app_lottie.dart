import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

/// Pre-bundled Lottie animation data embedded directly in Dart bytecode.
/// This guarantees 100% reliable, zero-latency animation playback even over
/// Shorebird Code Push patches without relying on base APK asset bundles.
class AppLottie {
  AppLottie._();

  static final Uint8List emptyInboxBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":90,"w":200,"h":200,"nm":"empty_inbox","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Chat Bubble","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":1,"k":[{"t":0,"s":[0]},{"t":45,"s":[3]},{"t":90,"s":[0]}]},"p":{"a":1,"k":[{"t":0,"s":[100,95,0]},{"t":45,"s":[100,85,0]},{"t":90,"s":[100,95,0]}]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[100,100,100]},{"t":45,"s":[104,104,100]},{"t":90,"s":[100,100,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[90,70]},"p":{"a":0,"k":[0,0]},"r":{"a":0,"k":18}},{"ty":"fl","c":{"a":0,"k":[0.15,0.45,0.95,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[40,8]},"p":{"a":0,"k":[0,-8]},"r":{"a":0,"k":4}},{"ty":"fl","c":{"a":0,"k":[1,1,1,0.9]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[25,8]},"p":{"a":0,"k":[-7,8]},"r":{"a":0,"k":4}},{"ty":"fl","c":{"a":0,"k":[1,1,1,0.7]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":2,"ty":4,"nm":"Shadow","sr":1,"ks":{"o":{"a":1,"k":[{"t":0,"s":[30]},{"t":45,"s":[15]},{"t":90,"s":[30]}]},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,155,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[100,100,100]},{"t":45,"s":[80,80,100]},{"t":90,"s":[100,100,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[80,18]},"p":{"a":0,"k":[0,0]}},{"ty":"fl","c":{"a":0,"k":[0.1,0.15,0.25,0.3]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget emptyInbox({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      emptyInboxBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static final Uint8List emptyNotificationsBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":200,"h":200,"nm":"empty_notifications","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Bell","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":1,"k":[{"t":0,"s":[0]},{"t":15,"s":[-14]},{"t":30,"s":[14]},{"t":45,"s":[-6]},{"t":60,"s":[0]}]},"p":{"a":0,"k":[100,85,0]},"a":{"a":0,"k":[0,-25,0]},"s":{"a":0,"k":[100,100,100]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[65,65]},"p":{"a":0,"k":[0,0]}},{"ty":"fl","c":{"a":0,"k":[0.95,0.65,0.15,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[22,22]},"p":{"a":0,"k":[0,32]}},{"ty":"fl","c":{"a":0,"k":[0.85,0.5,0.1,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget emptyNotifications({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      emptyNotificationsBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static final Uint8List emptySearchBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":200,"h":200,"nm":"empty_search","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Glass","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":1,"k":[{"t":0,"s":[-15]},{"t":30,"s":[15]},{"t":60,"s":[-15]}]},"p":{"a":1,"k":[{"t":0,"s":[90,95,0]},{"t":30,"s":[110,95,0]},{"t":60,"s":[90,95,0]}]},"a":{"a":0,"k":[0,0,0]},"s":{"a":0,"k":[100,100,100]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[60,60]},"p":{"a":0,"k":[-5,-5]}},{"ty":"st","c":{"a":0,"k":[0.2,0.5,0.95,1]},"w":{"a":0,"k":10},"o":{"a":0,"k":100}},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[10,36]},"p":{"a":0,"k":[26,26]},"r":{"a":0,"k":4}},{"ty":"fl","c":{"a":0,"k":[0.2,0.5,0.95,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":-45},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget emptySearch({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      emptySearchBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static final Uint8List emptyCallsBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":200,"h":200,"nm":"calls_empty","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Phone Handset","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":1,"k":[{"t":0,"s":[0]},{"t":6,"s":[-12]},{"t":12,"s":[12]},{"t":18,"s":[-10]},{"t":24,"s":[10]},{"t":30,"s":[-4]},{"t":36,"s":[4]},{"t":42,"s":[0]},{"t":60,"s":[0]}]},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[100,100,100]},{"t":15,"s":[108,108,100]},{"t":30,"s":[100,100,100]},{"t":60,"s":[100,100,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[72,72]},"p":{"a":0,"k":[0,0]}},{"ty":"fl","c":{"a":0,"k":[0.15,0.45,0.95,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[26,12]},"p":{"a":0,"k":[0,-18]},"r":{"a":0,"k":6}},{"ty":"fl","c":{"a":0,"k":[1,1,1,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[14,28]},"p":{"a":0,"k":[6,0]},"r":{"a":0,"k":6}},{"ty":"fl","c":{"a":0,"k":[1,1,1,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]},{"ty":"gr","it":[{"ty":"rc","d":1,"s":{"a":0,"k":[26,12]},"p":{"a":0,"k":[0,18]},"r":{"a":0,"k":6}},{"ty":"fl","c":{"a":0,"k":[1,1,1,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":2,"ty":4,"nm":"Wave 1","sr":1,"ks":{"o":{"a":1,"k":[{"t":0,"s":[0]},{"t":10,"s":[70]},{"t":40,"s":[0]},{"t":60,"s":[0]}]},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[80,80,100]},{"t":40,"s":[140,140,100]},{"t":60,"s":[80,80,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[80,80]},"p":{"a":0,"k":[0,0]}},{"ty":"st","c":{"a":0,"k":[0.15,0.45,0.95,1]},"w":{"a":0,"k":4},"o":{"a":0,"k":100}},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":3,"ty":4,"nm":"Wave 2","sr":1,"ks":{"o":{"a":1,"k":[{"t":15,"s":[0]},{"t":25,"s":[60]},{"t":55,"s":[0]},{"t":60,"s":[0]}]},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":15,"s":[80,80,100]},{"t":55,"s":[170,170,100]},{"t":60,"s":[80,80,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[80,80]},"p":{"a":0,"k":[0,0]}},{"ty":"st","c":{"a":0,"k":[0.15,0.45,0.95,1]},"w":{"a":0,"k":3},"o":{"a":0,"k":100}},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget emptyCalls({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      emptyCallsBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static final Uint8List voiceRecordingBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":40,"w":200,"h":200,"nm":"voice_recording","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Wave 0","sr":1,"ks":{"o":{"a":1,"k":[{"t":0,"s":[80]},{"t":20,"s":[20]},{"t":40,"s":[80]}]},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[50,50,100]},{"t":20,"s":[120,120,100]},{"t":40,"s":[50,50,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[60,60]},"p":{"a":0,"k":[0,0]}},{"ty":"st","c":{"a":0,"k":[0.95,0.2,0.3,1]},"w":{"a":0,"k":6},"o":{"a":0,"k":100}},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":2,"ty":4,"nm":"Wave 1","sr":1,"ks":{"o":{"a":1,"k":[{"t":0,"s":[80]},{"t":20,"s":[20]},{"t":40,"s":[80]}]},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":10,"s":[50,50,100]},{"t":30,"s":[120,120,100]},{"t":40,"s":[50,50,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[60,60]},"p":{"a":0,"k":[0,0]}},{"ty":"st","c":{"a":0,"k":[0.95,0.2,0.3,1]},"w":{"a":0,"k":6},"o":{"a":0,"k":100}},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":3,"ty":4,"nm":"Wave 2","sr":1,"ks":{"o":{"a":1,"k":[{"t":0,"s":[80]},{"t":20,"s":[20]},{"t":40,"s":[80]}]},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":20,"s":[50,50,100]},{"t":0,"s":[120,120,100]},{"t":40,"s":[50,50,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[60,60]},"p":{"a":0,"k":[0,0]}},{"ty":"st","c":{"a":0,"k":[0.95,0.2,0.3,1]},"w":{"a":0,"k":6},"o":{"a":0,"k":100}},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":4,"ty":4,"nm":"Mic Base","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[95,95,100]},{"t":20,"s":[108,108,100]},{"t":40,"s":[95,95,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[44,44]},"p":{"a":0,"k":[0,0]}},{"ty":"fl","c":{"a":0,"k":[0.95,0.2,0.3,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget voiceRecording({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      voiceRecordingBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static final Uint8List aiSparkleBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":60,"w":200,"h":200,"nm":"ai_sparkle","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Star Main","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":1,"k":[{"t":0,"s":[0]},{"t":30,"s":[180]},{"t":60,"s":[360]}]},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[90,90,100]},{"t":30,"s":[115,115,100]},{"t":60,"s":[90,90,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"sr","sy":2,"pt":{"a":0,"k":4},"p":{"a":0,"k":[0,0]},"r":{"a":0,"k":0},"ir":{"a":0,"k":14},"is":{"a":0,"k":0},"or":{"a":0,"k":42},"os":{"a":0,"k":0}},{"ty":"fl","c":{"a":0,"k":[0.45,0.25,0.95,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]},{"ddd":0,"ind":2,"ty":4,"nm":"Small Star","sr":1,"ks":{"o":{"a":1,"k":[{"t":0,"s":[40]},{"t":30,"s":[100]},{"t":60,"s":[40]}]},"r":{"a":1,"k":[{"t":0,"s":[360]},{"t":60,"s":[0]}]},"p":{"a":0,"k":[145,65,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[70,70,100]},{"t":30,"s":[110,110,100]},{"t":60,"s":[70,70,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"sr","sy":2,"pt":{"a":0,"k":4},"p":{"a":0,"k":[0,0]},"r":{"a":0,"k":0},"ir":{"a":0,"k":6},"is":{"a":0,"k":0},"or":{"a":0,"k":20},"os":{"a":0,"k":0}},{"ty":"fl","c":{"a":0,"k":[0.95,0.65,0.15,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget aiSparkle({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      aiSparkleBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static final Uint8List successCheckBytes = Uint8List.fromList(utf8.encode(r'''{"v":"5.7.4","fr":30,"ip":0,"op":45,"w":200,"h":200,"nm":"success_check","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"Circle","sr":1,"ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[0,0,100]},{"t":20,"s":[115,115,100]},{"t":30,"s":[100,100,100]}]}},"shapes":[{"ty":"gr","it":[{"ty":"el","d":1,"s":{"a":0,"k":[80,80]},"p":{"a":0,"k":[0,0]}},{"ty":"fl","c":{"a":0,"k":[0.15,0.75,0.45,1]},"o":{"a":0,"k":100},"r":1},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}]}'''));
  static Widget successCheck({
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.memory(
      successCheckBytes,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  static Widget fromAsset(
    String assetPath, {
    double? width,
    double? height,
    BoxFit? fit = BoxFit.contain,
    bool repeat = true,
  }) {
    if (assetPath.contains('inbox')) {
      return emptyInbox(width: width, height: height, fit: fit, repeat: repeat);
    }
    if (assetPath.contains('notification')) {
      return emptyNotifications(width: width, height: height, fit: fit, repeat: repeat);
    }
    if (assetPath.contains('search')) {
      return emptySearch(width: width, height: height, fit: fit, repeat: repeat);
    }
    if (assetPath.contains('call')) {
      return emptyCalls(width: width, height: height, fit: fit, repeat: repeat);
    }
    if (assetPath.contains('voice') || assetPath.contains('record')) {
      return voiceRecording(width: width, height: height, fit: fit, repeat: repeat);
    }
    if (assetPath.contains('sparkle') || assetPath.contains('ai')) {
      return aiSparkle(width: width, height: height, fit: fit, repeat: repeat);
    }
    if (assetPath.contains('check') || assetPath.contains('success')) {
      return successCheck(width: width, height: height, fit: fit, repeat: repeat);
    }
    return Lottie.asset(assetPath, width: width, height: height, fit: fit, repeat: repeat);
  }
}
