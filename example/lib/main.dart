import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rfidreaderplugin/rfidreaderplugin.dart';
import 'package:rfidreaderplugin/rfidreaderplugin_method_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _rfidreaderpluginPlugin = Rfidreaderplugin();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    getConnectionStateAndInitialize();
    setState(() {
      value = 1;
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _rfidreaderpluginPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  double value = 0;
  double outputLevel = 100;
  int batteryLevel = 0;
  bool isDeviceConnected = false;
  bool isScanning = false;
  List epcData = [];
  int epcCount = 0;
  Set<String> epcSet = {};

  void getConnectionStateAndInitialize() {
    final connectionStream = _rfidreaderpluginPlugin.connectionStatus();
    connectionStream.listen((dynamic event) {
      print("CONNECTION EVENT: $event");
    }).onData((dynamic event) {
      final data = event as bool;
      setState(() {
        isDeviceConnected = data;
        outputLevel = 100;
      });
      setBatteryLevel(data);
    });
  }

  void setBatteryLevel(bool isDeviceConnected) async {
    Future.delayed(
        const Duration(seconds: 5), () async {
      if(isDeviceConnected){
        final level = await _rfidreaderpluginPlugin.getBatteryPercentage();
        setState(() {
          batteryLevel = level!;
        });
      }
    }
    );
  }



  void onChanged(double newValue) async {
    setState(() {
      value = newValue;
      outputLevel = (newValue/1) * 100;
      });
    print(value);
  }


  void onChangeEnd(double newValue) async {
    final out = await _rfidreaderpluginPlugin.setOutputPowerLevel(newValue);
    print("OUTPUT POWER: $out");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor:  Color(0xFF010137),
        appBar: AppBar(
          title: const Text('RFiD Plugin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:Color(0xFF000022),
          foregroundColor: Colors.blueAccent,
          actions: [
            TextButton(
                onPressed: () {
                  setState(() {
                    epcData.clear();
                    epcSet.clear();
                    epcCount = 0;
                  }
                  );},
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all<Color>(Colors.amber),
                ),
                child: Text('Clear')
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(
              top: 60.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0, right: 18.0),
                      child: Divider(
                        color: Colors.blueAccent,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      height: 65,
                      decoration: BoxDecoration(
                        color: Color(0xFF000022),
                        border: Border.all(color: Colors.blueAccent),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(50, 120),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Battery: $batteryLevel%',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(width: 10),
                          batteryWidget(batteryLevel),
                        ],
                      ),
                    )
                  ]
              ),

              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Power Level: ${outputLevel.round()}%',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(width: 10),
                  powerLevelWidget(outputLevel.round()),
                ],
              ),
               Slider(
                value: isDeviceConnected ? value : 0,
                onChanged: isDeviceConnected ? onChanged : null,
                onChangeEnd: onChangeEnd,
                label: "Power Level",
                 activeColor: Color(0xFF2035FF),
              ),
              SizedBox(height: 15),
              Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0, right: 18.0),
                      child: Divider(
                        color: Colors.blueAccent,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF000022),
                        border: Border.all(color: Colors.blueAccent),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(50, 120),
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                            text: 'Status:',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                  text: isDeviceConnected ? ' Connected' : ' Not Connected',
                                  style: TextStyle(
                                    color: isDeviceConnected ? Colors.green : Colors.red,
                                    fontSize: 25,
                                    fontStyle: FontStyle.italic,
                                  )
                              )
                            ]
                        ),
                      )
                    )
                  ]
              ),
              SizedBox(height: 15),
              OutlinedButton(onPressed: () async {
                final batteryPercentage = await _rfidreaderpluginPlugin.getBatteryPercentage();
                setState(() {
                  batteryLevel = batteryPercentage!;
                });
                final level = await _rfidreaderpluginPlugin.getPowerBarLimits();
                print(level?['min']);
                print(level?['max']);
              },
                  child: Text(
                "Get Battery Percentage",
                    style: TextStyle(
                      color: Colors.blueAccent,
                    )
              )),
              OutlinedButton(onPressed: isScanning? null : () async {
              if (await _rfidreaderpluginPlugin.connectReader()) {
                // setState(() {
                //   isDeviceConnected = true;
                // });
              }
              },
                  style: ButtonStyle(
                    backgroundColor: isScanning ? WidgetStateProperty.all<Color>(Colors.grey.withOpacity(0.5)) :
                    WidgetStateProperty.all<Color>(Color(0xFF875A00).withOpacity(0.5)),
                  ),
                  child: Text(
                "Connect Device",
                    style: TextStyle(
                      color: isScanning ? Color(0xFF3A3A3A) : Color(0xFFF4AD1A),
                    )
              )),
              OutlinedButton(onPressed: () async {
                final isDisconnected = await _rfidreaderpluginPlugin.disconnectReader();
                print(isDisconnected);
                setState(() {
                  isDeviceConnected = false;
                  outputLevel = 0;
                  epcData.clear();
                  epcSet.clear();
                  epcCount = 0;
                });
                batteryLevel = 0;
              },
                  child: Text(
                "Disconnect",
                style: TextStyle(
                  color: Colors.blueAccent,
                ),
              )),
              FilledButton(
                  onPressed: isScanning || !isDeviceConnected ? null : () async {
                final scanStream = _rfidreaderpluginPlugin.scanStart();
                scanStream.listen((dynamic event) {
                  print("EVENT: $event");
                }).onData((dynamic event) {
                  final resultMap = <String, dynamic>{};
                  final data = event as Map;
                  if (data.isNotEmpty) {
                    for(var key in data.keys) {
                      resultMap[key] = data[key];
                      if (!epcSet.contains(resultMap['epc'])) {
                        epcSet.add(resultMap['epc']);
                        setState(() {
                          epcCount = epcSet.length;
                         // epcCount++;
                        });
                      }
                    }
                  }
                  print("DATA EVENT: $event");
                  print("EPC DATA SET: $epcSet");
                });

                setState(() {
                  isScanning = true;
                });
                },
                  style: ButtonStyle(
                backgroundColor: isScanning || !isDeviceConnected ? WidgetStateProperty.all<Color>(Colors.grey) :
                WidgetStateProperty.all<Color>(Colors.green),
                  ),
                  child: Text(
                "Start Scan",
                    style: TextStyle(
                      color: isScanning || !isDeviceConnected ? Color(0xFF3A3A3A) : Color(0xFF143003),
                    )
              )),
              FilledButton(onPressed: !isDeviceConnected ? null : () async {
                final isScanStopped = await _rfidreaderpluginPlugin.scanStop();
                setState(() {
                  isScanning = false;
                });
                print(isScanStopped);
                },
                  style: ButtonStyle(
                    backgroundColor:  !isDeviceConnected ? WidgetStateProperty.all<Color>(Colors.grey) :
                    WidgetStateProperty.all<Color>(Color(0xFFFF5E62)),
                  ),
                  child: Text(
                "Stop Scan",
                    style: TextStyle(
                      color: !isDeviceConnected ? Color(0xFF3A3A3A) : Color(0xFF570101),
                    )
              )),
              SizedBox(height: 15),
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 18.0, right: 18.0),
                    child: Divider(
                      color: Colors.blueAccent,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF000022),
                      border: Border.all(color: Colors.blueAccent),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(50, 120),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                          text: 'EPC Count: ',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                                text: '$epcCount',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                )
                            )
                          ]
                      ),
                    ),
                  )
                ]
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget batteryWidget(int batteryLevel) {
    return
        RotatedBox(
          quarterTurns: 1,
          child: Icon(
            batteryLevel >= 80 ? Icons.battery_full
                : batteryLevel >= 60 ? Icons.battery_6_bar
                : batteryLevel >= 50 ? Icons.battery_5_bar
                : batteryLevel >= 40 ? Icons.battery_4_bar
                : batteryLevel >= 20 ? Icons.battery_2_bar
                : batteryLevel >= 10 ? Icons.battery_1_bar
                : Icons.battery_alert,
            color: batteryLevel >= 80 ? Colors.green
                : batteryLevel >= 60 ? Colors.green
                : batteryLevel >= 50 ? Colors.green
                : batteryLevel >= 40 ? Colors.green
                : batteryLevel >= 20 ? Colors.yellow
                : batteryLevel >= 10 ? Colors.orange
                : Colors.red,
            size: 45,
          ),
        );
  }

  Widget powerLevelWidget(int outputLevel) {
    return
        Icon(
          outputLevel >= 80 ? Icons.signal_cellular_alt
              : outputLevel >= 50 ? Icons.signal_cellular_alt_2_bar_sharp
              : outputLevel >= 10 ? Icons.signal_cellular_alt_1_bar
              : outputLevel >= 4 ? Icons.signal_cellular_alt_1_bar
              : Icons.signal_cellular_connected_no_internet_0_bar,
          color: outputLevel >= 80 ? Colors.green
              : outputLevel >= 50 ? Colors.green
              : outputLevel >= 10 ? Colors.orange
              : outputLevel >= 4 ? Colors.red
              : Colors.grey,
          size: 50,
        );
  }
}
