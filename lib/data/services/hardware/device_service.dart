import 'package:flutter/services.dart';

class DeviceInfoService {
  static const _method = MethodChannel('pocketlm/device');

  Future<DeviceData> getDeviceInfo() async {
    final data = await _method.invokeMapMethod<String, dynamic>('getDeviceInfo');
    return DeviceData.fromMap(data!);
  }
}

class DeviceData {
  final String brand;
  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkVersion;
  final String hardware;
  final List<String> abis;
  final bool isArm64;
  final int totalStorage;
  final int availStorage;

  const DeviceData({
    required this.brand,
    required this.manufacturer,
    required this.model,
    required this.androidVersion,
    required this.sdkVersion,
    required this.hardware,
    required this.abis,
    required this.isArm64,
    required this.totalStorage,
    required this.availStorage,
  });

  double get totalStorageGb => totalStorage / (1024 * 1024 * 1024);
  double get availStorageGb => availStorage / (1024 * 1024 * 1024);
  String get fullName => '$manufacturer $model';

  factory DeviceData.fromMap(Map<String, dynamic> map) {
    return DeviceData(
      brand: map['brand'] as String,
      manufacturer: map['manufacturer'] as String,
      model: map['model'] as String,
      androidVersion: map['androidVersion'] as String,
      sdkVersion: map['sdkVersion'] as int,
      hardware: map['hardware'] as String,
      abis: List<String>.from(map['abis'] ?? []),
      isArm64: map['isArm64'] as bool,
      totalStorage: map['totalStorage'] as int,
      availStorage: map['availStorage'] as int,
    );
  }
}