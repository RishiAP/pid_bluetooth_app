import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';

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
  double _pvalue = 0, _ivalue = 0, _dvalue = 0,_speed=0;
  final _bluetoothClassicPlugin = BluetoothClassic();
  List<Device> _devices = [];
  List<Device> _discoveredDevices = [];
  bool _scanning = false;
  int _deviceStatus = Device.disconnected;
  Uint8List _data = Uint8List(0);
  @override
  void initState() {
    super.initState();
    initPlatformState();
    _bluetoothClassicPlugin.onDeviceStatusChanged().listen((event) {
      setState(() {
        _deviceStatus = event;
      });
    });
    _bluetoothClassicPlugin.onDeviceDataReceived().listen((event) {
      setState(() {
        _data = Uint8List.fromList(event);
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _bluetoothClassicPlugin.getPlatformVersion() ??
          'Unknown platform version';
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

  Future<void> _getDevices() async {
    var res = await _bluetoothClassicPlugin.getPairedDevices();
    setState(() {
      _devices = res;
    });
  }

  Future<void> _scan() async {
    if (_scanning) {
      await _bluetoothClassicPlugin.stopScan();
      setState(() {
        _scanning = false;
      });
    } else {
      await _bluetoothClassicPlugin.startScan();
      _bluetoothClassicPlugin.onDeviceDiscovered().listen(
        (event) {
          setState(() {
            _discoveredDevices = [..._discoveredDevices, event];
          });
        },
      );
      setState(() {
        _scanning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PID Bluetooth Control'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Text("Device status is $_deviceStatus"),
              TextButton(
                onPressed: () async {
                  await _bluetoothClassicPlugin.initPermissions();
                },
                child: const Text("Check Permissions"),
              ),
              TextButton(
                onPressed: _getDevices,
                child: const Text("Get Paired Devices"),
              ),
              TextButton(
                onPressed: _deviceStatus == Device.connected
                    ? () async {
                        await _bluetoothClassicPlugin.disconnect();
                      }
                    : null,
                child: const Text("disconnect"),
              ),
              TextButton(
                onPressed: _deviceStatus == Device.connected
                    ? () async {
                        await _bluetoothClassicPlugin.write("ping");
                      }
                    : null,
                child: const Text("send ping"),
              ),
              Center(
                child: Text('Running on: $_platformVersion\n'),
              ),
              ...[
                for (var device in _devices)
                  TextButton(
                      onPressed: () async {
                        await _bluetoothClassicPlugin.connect(device.address,
                            "00001101-0000-1000-8000-00805f9b34fb");
                        setState(() {
                          _discoveredDevices = [];
                          _devices = [];
                        });
                      },
                      child: Text(device.name ?? device.address))
              ],
              TextButton(
                onPressed: _scan,
                child: Text(_scanning ? "Stop Scan" : "Start Scan"),
              ),
              ...[
                for (var device in _discoveredDevices)
                  Text(device.name ?? device.address)
              ],
              Text("Received data: ${String.fromCharCodes(_data)}"),
              Text("Speed : $_speed",style: const TextStyle(fontSize: 15),),
              const SizedBox(height: 30,),
              Slider(
                value: _speed,
                min: 0,
                max: 255,
                divisions: 255,
                label: _speed.toString(),
                onChanged: (double value) {
                  setState(() {
                    _speed = value;
                  });
                },
                onChangeEnd: (double value)async{
                  if (_deviceStatus == Device.connected) {
                    await _bluetoothClassicPlugin.write("{\"bS\":$value,\"Kp\":$_pvalue,\"Ki\":$_ivalue,\"Kd\":$_dvalue}");
                  }
                },
              ),
              Text("P : $_pvalue",style: const TextStyle(fontSize: 15),),
              const SizedBox(height: 30,),
              Slider(
                value: _pvalue,
                min: 0,
                max: 1,
                divisions: 100,
                label: _pvalue.toString(),
                onChanged: (double value) {
                  setState(() {
                    _pvalue = value;
                  });
                },
                onChangeEnd: (double value)async{
                  if (_deviceStatus == Device.connected) {
                    await _bluetoothClassicPlugin.write("{\"bS\":$_speed,\"Kp\":$value,\"Ki\":$_ivalue,\"Kd\":$_dvalue}");
                  }
                },
              ),
              Text("I : $_ivalue",style: const TextStyle(fontSize: 15),),
              const SizedBox(height: 30,),
              Slider(
                value: _ivalue,
                min: 0,
                max: 1,
                divisions: 100,
                label: _ivalue.toString(),
                onChanged: (double value) {
                  setState(() {
                    _ivalue = value;
                  });
                },
                onChangeEnd: (double value)async{
                  if (_deviceStatus == Device.connected) {
                    await _bluetoothClassicPlugin.write("{\"bS\":$_speed,\"Kp\":$_pvalue,\"Ki\":$value,\"Kd\":$_dvalue}");
                  }
                },
              ),
              Text("D : $_dvalue",style: const TextStyle(fontSize: 15),),
              const SizedBox(height: 30,),
              Slider(
                value: _dvalue,
                min: 0,
                max: 1,
                divisions: 100,
                label: _dvalue.toString(),
                onChanged: (double value) {
                  setState(() {
                    _dvalue = value;
                  });
                },
                onChangeEnd: (double value)async{
                  if (_deviceStatus == Device.connected) {
                    await _bluetoothClassicPlugin.write("{\"bS\":$_speed,\"Kp\":$_pvalue,\"Ki\":$_ivalue,\"Kd\":$value}");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
