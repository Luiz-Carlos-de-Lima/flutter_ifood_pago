import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_ifood_pago_platform_interface.dart';

/// An implementation of [FlutterIfoodPagoPlatform] that uses method channels.
class MethodChannelFlutterIfoodPago extends FlutterIfoodPagoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ifood_pago');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
