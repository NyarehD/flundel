import 'package:flutter_soloud/flutter_soloud.dart';

// flutter_soloud 5.2.1 has no public per-bus visualization switch, though its
// Bus.getChannelVolume implementation requires it. Keep this version-pinned
// native call isolated so an upgrade can replace it with a public API.
// ignore: implementation_imports
import 'package:flutter_soloud/src/bindings/flutter_soloud_ffigen.dart'
    as soloud_native;

void enableBusMeter(Bus bus) {
  soloud_native.busSetVisualizationEnable(bus.busId, true);
}
