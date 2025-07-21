import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ifood_pago/flutter_ifood_pago.dart';
import 'package:flutter_ifood_pago/flutter_ifood_pago_platform_interface.dart';
import 'package:flutter_ifood_pago/flutter_ifood_pago_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterIfoodPagoPlatform
    with MockPlatformInterfaceMixin
    implements FlutterIfoodPagoPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterIfoodPagoPlatform initialPlatform = FlutterIfoodPagoPlatform.instance;

  test('$MethodChannelFlutterIfoodPago is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterIfoodPago>());
  });

  test('getPlatformVersion', () async {
    FlutterIfoodPago flutterIfoodPagoPlugin = FlutterIfoodPago();
    MockFlutterIfoodPagoPlatform fakePlatform = MockFlutterIfoodPagoPlatform();
    FlutterIfoodPagoPlatform.instance = fakePlatform;

    expect(await flutterIfoodPagoPlugin.getPlatformVersion(), '42');
  });
}
