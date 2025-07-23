import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityUtils = Provider((ref) => SecurityUtils());

class SecurityUtils{

  Future<bool> isDeviceJailBroken() async{
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } on PlatformException {
      return true;
    }
  }
}