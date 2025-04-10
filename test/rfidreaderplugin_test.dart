import 'package:flutter_test/flutter_test.dart';
import 'package:rfidreaderplugin/rfidreaderplugin.dart';
import 'package:rfidreaderplugin/rfidreaderplugin_platform_interface.dart';
import 'package:rfidreaderplugin/rfidreaderplugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRfidreaderpluginPlatform
    with MockPlatformInterfaceMixin
    implements RfidreaderpluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> connectReader() {
    // TODO: implement connectReader
    throw UnimplementedError();
  }

  @override
  Future<bool> disconnectReader() {
    // TODO: implement disconnectReader
    throw UnimplementedError();
  }

  @override
  Future<int?> getBatteryPercentage() {
    // TODO: implement getBatteryPercentage
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getPowerBarLimits() {
    // TODO: implement getPowerBarLimits
    throw UnimplementedError();
  }

  @override
  Future<int?> getOutputPowerLevel() {
    // TODO: implement getOutputPowerLevel
    throw UnimplementedError();
  }

  @override
  Stream scanStart() {
    // TODO: implement scanStart
    throw UnimplementedError();
  }

  @override
  Future<bool> scanStop() {
    // TODO: implement scanStop
    throw UnimplementedError();
  }

  @override
  Future<double> setOutputPowerLevel(double level) {
    // TODO: implement setOutputPowerLevel
    throw UnimplementedError();
  }

  @override
  Stream connectionStatus() {
    // TODO: implement connectionStatus
    throw UnimplementedError();
  }
}

void main() {
  final RfidreaderpluginPlatform initialPlatform = RfidreaderpluginPlatform.instance;

  test('$MethodChannelRfidreaderplugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRfidreaderplugin>());
  });

  test('getPlatformVersion', () async {
    Rfidreaderplugin rfidreaderpluginPlugin = Rfidreaderplugin();
    MockRfidreaderpluginPlatform fakePlatform = MockRfidreaderpluginPlatform();
    RfidreaderpluginPlatform.instance = fakePlatform;

    expect(await rfidreaderpluginPlugin.getPlatformVersion(), '42');
  });
}
