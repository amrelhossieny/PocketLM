import 'cpu_service.dart';
import 'device_service.dart';
import 'gpu_service.dart';
import 'ram_service.dart';

class HardwareService {
  final ram = RamService();
  final cpu = CpuService();
  final gpu = GpuService();
  final device = DeviceInfoService();

  /// Get all hardware info at once
  Future<HardwareSnapshot> getSnapshot() async {
    final results = await Future.wait([
      ram.getRamInfo(),
      cpu.getCpuInfo(),
      gpu.getGpuInfo(),
      device.getDeviceInfo(),
    ]);

    return HardwareSnapshot(
      ram: results[0] as RamData,
      cpu: results[1] as CpuData,
      gpu: results[2] as GpuData,
      device: results[3] as DeviceData,
    );
  }
}

class HardwareSnapshot {
  final RamData ram;
  final CpuData cpu;
  final GpuData gpu;
  final DeviceData device;

  const HardwareSnapshot({
    required this.ram,
    required this.cpu,
    required this.gpu,
    required this.device,
  });
}