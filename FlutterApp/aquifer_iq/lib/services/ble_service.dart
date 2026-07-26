import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SensorData {
  final double tds;
  final double purity;
  final double temperature;
  final double ph; // New field

  SensorData({
    required this.tds,
    required this.purity,
    required this.temperature,
    required this.ph,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      tds:         (json['tds']    ?? 0).toDouble(),
      purity:      (json['purity'] ?? 0).toDouble(),
      temperature: (json['temp']   ?? 0).toDouble(),
      ph:          (json['ph']     ?? 7.0).toDouble(), // Default to neutral pH
    );
  }

  factory SensorData.empty() {
    return SensorData(tds: 0, purity: 0, temperature: 0, ph: 0);
  }
}

class BleService extends ChangeNotifier {
  static const String SERVICE_UUID        = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? _device;
  bool       _isConnected    = false;
  bool       _isScanning     = false;
  bool       _foundAndConnecting = false;
  SensorData _sensorData     = SensorData.empty();
  String     _statusMessage  = "Not connected";

  bool _isSimulationMode = false;
  bool _isCapturing = false;
  Timer? _simulationTimer;

  StreamSubscription? _scanResultsSub;
  StreamSubscription? _isScanningSubStream;
  StreamSubscription? _connectionStateSub;

  bool       get isConnected   => _isConnected;
  bool       get isScanning    => _isScanning || _foundAndConnecting;
  SensorData get sensorData    => _sensorData;
  String     get statusMessage => _statusMessage;
  bool       get isSimulationMode => _isSimulationMode;
  bool       get isCapturing      => _isCapturing;

  void toggleSimulationMode() {
    _isSimulationMode = !_isSimulationMode;
    if (_isSimulationMode) {
      _startSimulation();
    } else {
      _stopSimulation();
      disconnect();
    }
    notifyListeners();
  }

  void _startSimulation() {
    _stopSimulation();
    _isConnected = true;
    _statusMessage = "Simulation Mode";

    _simulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      // إذا كان في وضع التقاط صورة، لا نحدث البيانات لحين انتهاء الالتقاط
      if (_isCapturing) return;
      final random = Random();
      _sensorData = SensorData(
        tds: 100 + random.nextDouble() * 900,
        purity: 60 + random.nextDouble() * 40,
        temperature: 15 + random.nextDouble() * 20,
        ph: 6.5 + random.nextDouble() * 2.0, // 6.5 to 8.5 (Common range)
      );
      notifyListeners();
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  Future<void> startScan() async {
    if (_isSimulationMode) return;
    if (_isScanning || _isConnected || _foundAndConnecting) return;

    // 1. تصفير البيانات عند بدء بحث جديد
    _sensorData = SensorData.empty();

    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        _statusMessage = "Bluetooth permissions denied";
        notifyListeners();
        return;
      }
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _statusMessage = "Turn on Bluetooth first";
      notifyListeners();
      return;
    }

    _isScanning    = true;
    _statusMessage = "Scanning...";
    notifyListeners();

    await _scanResultsSub?.cancel();
    await _isScanningSubStream?.cancel();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.advName;

        if (name.toLowerCase().contains("aquifer")) {
          _foundAndConnecting = true;
          _isScanning         = false;
          notifyListeners();

          FlutterBluePlus.stopScan();
          _scanResultsSub?.cancel();
          _connectToDevice(r.device);
          break;
        }
      }
    });

    _isScanningSubStream = FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && !_isConnected && !_foundAndConnecting) {
        _isScanning    = false;
        _statusMessage = "Device not found";
        notifyListeners();
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;

    try {
      // إلغاء أي مراقبة قديمة للاتصال قبل بدء اتصال جديد
      await _connectionStateSub?.cancel();

      // 2. مراقبة حالة الاتصال بشكل فوري
      _connectionStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected        = false;
          _foundAndConnecting = false;
          _statusMessage      = "Disconnected";

          // تصفير القراءات فور الانقطاع
          _sensorData = SensorData.empty();

          notifyListeners();
          debugPrint("Disconnected: Data has been reset.");
        }
      });

      await device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 10),
      );

      _isConnected        = true;
      _isScanning         = false;
      _foundAndConnecting = false;
      _statusMessage      = "Connected";
      notifyListeners();

      final services = await device.discoverServices();
      for (final service in services) {
        for (final c in service.characteristics) {
          final isOurChar = c.uuid.toString().toLowerCase() ==
              CHARACTERISTIC_UUID.toLowerCase();
          final canNotify = c.properties.notify || c.properties.indicate;

          if (isOurChar || canNotify) {
            await _subscribeToNotifications(c);
            break;
          }
        }
      }

    } catch (e) {
      _isConnected        = false;
      _isScanning         = false;
      _foundAndConnecting = false;
      _statusMessage      = "Connection failed";
      _sensorData         = SensorData.empty();
      notifyListeners();
      debugPrint("Connect Error: $e");
    }
  }

  Future<void> _subscribeToNotifications(BluetoothCharacteristic c) async {
    try {
      if (c.isNotifying) {
        await c.setNotifyValue(false);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      await c.setNotifyValue(true);

      c.lastValueStream.listen((value) {
        if (value.isEmpty || !_isConnected) return;
        // إذا كان في وضع التقاط صورة، لا نحدث البيانات لحين انتهاء الالتقاط
        if (_isCapturing) return;
        try {
          final raw  = utf8.decode(value);
          final json = jsonDecode(raw) as Map<String, dynamic>;
          _sensorData = SensorData.fromJson(json);
          notifyListeners();
        } catch (e) {
          debugPrint("Parse error: $e");
        }
      });

    } catch (e) {
      debugPrint("setNotifyValue error: $e");
    }
  }

  /// يجمد القراءات قبل التقاط الصورة
  void startCapture() {
    _isCapturing = true;
    notifyListeners();
  }

  /// يرجع تحديث القراءات بعد التقاط الصورة
  void endCapture() {
    _isCapturing = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_isSimulationMode) {
      _stopSimulation();
      _isConnected = false;
      _statusMessage = "Not connected";
      _sensorData = SensorData.empty();
      notifyListeners();
      return;
    }

    await FlutterBluePlus.stopScan();
    await _scanResultsSub?.cancel();
    await _isScanningSubStream?.cancel();
    await _connectionStateSub?.cancel();
    await _device?.disconnect();

    _isConnected        = false;
    _isScanning         = false;
    _foundAndConnecting = false;
    _statusMessage      = "Not connected";
    _sensorData         = SensorData.empty();
    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _connectionStateSub?.cancel();
    disconnect();
    super.dispose();
  }
}
