import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rfidreaderplugin_platform_interface.dart';

/// An implementation of [RfidreaderpluginPlatform] that uses method channels.
class MethodChannelRfidreaderplugin extends RfidreaderpluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rfidreadermethodchannel');
  final eventChannel = const EventChannel('rfidreadereventchannel');
  final connectionEventChannel = const EventChannel('rfidreaderconnectioneventchannel');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<int?> getBatteryPercentage () async {
    final batteryPercentage = await methodChannel.invokeMethod<int>('getBatteryPercentage');
    return batteryPercentage;
  }

  @override
  Future<Map<String, dynamic>?> getPowerBarLimits () async {
    try {
      final resultMap = <String, dynamic>{};
      final result = await methodChannel.invokeMethod('getPowerBarLimits');
      if (result != null) {
        for(var key in result.keys) {
          resultMap[key] = result[key];
        }
        return resultMap;
      }
      return null ;
    } on PlatformException catch (e) {
      print('ERROR GETTING LIMITS: $e');
      return null;
    }
  }

  @override
  Future<int?> getOutputPowerLevel () async {
    final powerLevel = await methodChannel.invokeMethod<int>('getOutputPowerLevel');
    return powerLevel;
  }

  @override
  Future<double> setOutputPowerLevel (double level) async {
    final outPutPowerLevel = await methodChannel.invokeMethod<double>('setOutputPowerLevel', level);
    return outPutPowerLevel!;
  }

  @override
  Future<bool> connectReader() async {
    final currentReader = await methodChannel.invokeMethod<bool>('connectReader');
    return currentReader!;
  }

  @override
  Future<bool> disconnectReader() async {
    final isDisconnected = await methodChannel.invokeMethod<bool>('disconnectReader');
    return isDisconnected!;
  }

  @override
  Stream<dynamic> scanStart() {
    final scanEvent = eventChannel.receiveBroadcastStream();
    return scanEvent;
  }

  @override
  Future<bool> scanStop() async {
    final isScanStopped = await methodChannel.invokeMethod<bool>('scanStop');
    return isScanStopped!;
  }

  @override
  Stream<dynamic> connectionStatus() {
      final connectionStatus = connectionEventChannel.receiveBroadcastStream();
      return connectionStatus;
  }
}
