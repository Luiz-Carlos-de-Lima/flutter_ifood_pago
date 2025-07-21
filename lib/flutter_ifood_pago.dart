
import 'flutter_ifood_pago_platform_interface.dart';

class FlutterIfoodPago {
  Future<String?> getPlatformVersion() {
    return FlutterIfoodPagoPlatform.instance.getPlatformVersion();
  }
}
