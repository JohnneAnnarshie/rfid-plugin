import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rfidreaderplugin_method_channel.dart';

abstract class RfidreaderpluginPlatform extends PlatformInterface {
  /// Constructs a RfidreaderpluginPlatform.
  RfidreaderpluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static RfidreaderpluginPlatform _instance = MethodChannelRfidreaderplugin();

  /// The default instance of [RfidreaderpluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelRfidreaderplugin].
  static RfidreaderpluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RfidreaderpluginPlatform] when
  /// they register themselves.
  static set instance(RfidreaderpluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<int?> getBatteryPercentage () {
    throw UnimplementedError('getBatteryPercentage() has not been implemented.');
  }

  Future<Map<String, dynamic>?> getPowerBarLimits () {
    throw UnimplementedError('getPowerBarLimits() has not been implemented.');
  }

  Future<int?> getOutputPowerLevel () {
    throw UnimplementedError('getOutputPowerLevel() has not been implemented.');
  }

  Future<double> setOutputPowerLevel (double level) {
    throw UnimplementedError('setOutputPowerLevel() has not been implemented.');
  }

  Future<bool> connectReader () {
    throw UnimplementedError('connectReader() has not been implemented.');
  }

  Future<bool> disconnectReader () {
    throw UnimplementedError('disconnectReader() has not been implemented.');
  }

  Stream<dynamic> scanStart () {
    throw UnimplementedError('scanStart() has not been implemented.');
  }

  Future<bool> scanStop () {
    throw UnimplementedError('scanStop() has not been implemented.');
  }

  Stream<dynamic> connectionStatus () {
    throw UnimplementedError('connectionStatus() has not been implemented.');
  }


}
