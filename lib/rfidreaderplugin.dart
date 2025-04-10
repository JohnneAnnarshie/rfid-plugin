
import 'rfidreaderplugin_platform_interface.dart';

class Rfidreaderplugin {
  Future<String?> getPlatformVersion() {
    return RfidreaderpluginPlatform.instance.getPlatformVersion();
  }

  Future<int?> getBatteryPercentage () {
    return RfidreaderpluginPlatform.instance.getBatteryPercentage();
  }

  Future<Map<String, dynamic>?> getPowerBarLimits () {
    return RfidreaderpluginPlatform.instance.getPowerBarLimits();
  }

  Future<int?> getOutputPowerLevel () {
    return RfidreaderpluginPlatform.instance.getOutputPowerLevel();
  }

  Future<double> setOutputPowerLevel (double level) {
    return RfidreaderpluginPlatform.instance.setOutputPowerLevel(level);
  }

  Future<bool> connectReader () {
    return RfidreaderpluginPlatform.instance.connectReader();
  }

  Future<bool> disconnectReader () {
    return RfidreaderpluginPlatform.instance.disconnectReader();
  }

  Stream<dynamic> scanStart () {
    return RfidreaderpluginPlatform.instance.scanStart();
  }

  Future<bool> scanStop () {
    return RfidreaderpluginPlatform.instance.scanStop();
  }

  Stream<dynamic> connectionStatus () {
    return RfidreaderpluginPlatform.instance.connectionStatus();
  }

}
