import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfidreaderplugin/rfidreaderplugin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelRfidreaderplugin platform = MethodChannelRfidreaderplugin();
  const MethodChannel channel = MethodChannel('rfidreaderplugin');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
