import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class EntregadorLocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSub;

  /// Inicia rastreamento
  Future<void> startTracking({
    required String pedidoId,
    required String entregadorId,
  }) async {
    // 1) Permissões
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      throw Exception('Permissão de localização negada.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado.');
    }

    // 2) Configura captura contínua
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    // Cancela streams anteriores
    await _positionSub?.cancel();

    // 3) Inicia stream em tempo real
    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) async {
      await _db.collection('pedidos').doc(pedidoId).update({
        'entregadorId': entregadorId,
        'entregadorLat': pos.latitude,
        'entregadorLng': pos.longitude,
        'entregadorLastUpdate': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Para rastreamento
  Future<void> stopTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  /// Permissões de GPS
  Future<bool> _checkAndRequestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.deniedForever) {
      return false;
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }
}
