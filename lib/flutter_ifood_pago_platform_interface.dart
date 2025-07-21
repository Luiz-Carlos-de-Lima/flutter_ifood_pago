import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_ifood_pago_method_channel.dart';

abstract class FlutterIfoodPagoPlatform extends PlatformInterface {
  /// Constructs a FlutterIfoodPagoPlatform.
  FlutterIfoodPagoPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterIfoodPagoPlatform _instance = MethodChannelFlutterIfoodPago();

  /// The default instance of [FlutterIfoodPagoPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterIfoodPago].
  static FlutterIfoodPagoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterIfoodPagoPlatform] when
  /// they register themselves.
  static set instance(FlutterIfoodPagoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
