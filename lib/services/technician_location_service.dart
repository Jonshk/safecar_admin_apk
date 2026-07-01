// lib/services/technician_location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Maneja el envío del GPS del técnico mientras una grúa está
/// "in_progress". Usa un foreground service de Android (notificación
/// persistente visible) para seguir funcionando aunque el admin
/// minimice la app — sin necesitar el permiso "ubicación todo el
/// tiempo", que es mucho más invasivo de pedir.
///
/// Solo trackea UNA grúa a la vez (asume un técnico/dispositivo por
/// servicio activo, que es como quedó definido el flujo).
class TechnicianLocationService {
  TechnicianLocationService._();
  static final instance = TechnicianLocationService._();

  StreamSubscription<Position>? _sub;
  int? _activeTowId;

  bool get isTracking => _sub != null;
  int? get activeTowId => _activeTowId;

  /// Pide los permisos necesarios. Retorna false si el usuario los
  /// negó — en ese caso no se debe llamar a start().
  Future<bool> ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Arranca el envío periódico de GPS para [towId]. Si ya había otra
  /// grúa siendo trackeada, la detiene primero.
  Future<void> start(int towId) async {
    if (_activeTowId == towId && isTracking) return;
    await stop();

    final granted = await ensurePermissions();
    if (!granted) return;

    _activeTowId = towId;

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: Duration(seconds: 30),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationText: 'Compartiendo tu ubicación con el cliente',
        notificationTitle: 'Safe Car Admin · Servicio en camino',
        enableWakeLock: true,
        notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
      ),
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        ApiService.updateTechnicianLocation(
          towId,
          position.latitude,
          position.longitude,
        );
      },
      onError: (_) {
        // Si el stream falla (GPS apagado a mitad de servicio, etc.),
        // simplemente se detiene; el admin puede reintentar
        // reabriendo la app o re-seleccionando el estado.
        stop();
      },
    );
  }

  /// Detiene el envío de GPS — se llama cuando el estado deja de ser
  /// in_progress (completed, cancelled, o si el admin retrocede).
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _activeTowId = null;
  }
}