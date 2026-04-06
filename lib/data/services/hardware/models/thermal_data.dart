import '../ffi/hardware_ffi.dart';

class ThermalData {
  final double socTemperatureCelsius;
  final bool isThrottling;
  final bool isCritical;

  const ThermalData({
    required this.socTemperatureCelsius,
    required this.isThrottling,
    required this.isCritical,
  });

  String get temperatureLabel {
    if (socTemperatureCelsius < 0) return 'N/A';
    return '${socTemperatureCelsius.toStringAsFixed(1)}°C';
  }

  ThermalStatus get status {
    if (isCritical)                 return ThermalStatus.critical;
    if (isThrottling)               return ThermalStatus.throttling;
    if (socTemperatureCelsius > 60) return ThermalStatus.warm;
    return ThermalStatus.normal;
  }

  factory ThermalData.fromFFI(ThermalSnapshotFFI ffi) {
    return ThermalData(
      socTemperatureCelsius: ffi.socTemperatureCelsius,
      isThrottling:          ffi.isThrottling == 1,
      isCritical:            ffi.isCritical   == 1,
    );
  }
}

enum ThermalStatus { normal, warm, throttling, critical }

extension ThermalStatusExt on ThermalStatus {
  String get label {
    switch (this) {
      case ThermalStatus.normal:     return 'Normal';
      case ThermalStatus.warm:       return 'Warm';
      case ThermalStatus.throttling: return 'Throttling';
      case ThermalStatus.critical:   return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case ThermalStatus.normal:     return '✅';
      case ThermalStatus.warm:       return '🟡';
      case ThermalStatus.throttling: return '🟠';
      case ThermalStatus.critical:   return '🔥';
    }
  }
}