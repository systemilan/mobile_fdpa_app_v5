import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/environment.dart';

/// Todos los eventos emitidos por el backend via Socket.IO
const List<String> _kSocketEvents = [
  'event:created',
  'event:updated',
  'event:deleted',
  'eventJornada:created',
  'eventJornada:deleted',
  'eventTest:created',
  'eventTest:updated',
  'eventTest:deleted',
  'eventTest:nameUpdated',
  'series:created',
  'series:updated',
  'series:deleted',
  'series:renamedAll',
  'lifData:uploaded',
  'lifData:created',
  'lifData:updated',
  'lifData:deleted',
  'lynx:group:start',
  'lynx:group:done',
  'lynx:import:complete',
];

/// Servicio singleton de Socket.IO.
///
/// Mantiene una conexión persistente durante toda la vida de la app
/// y expone streams broadcast tipados por nombre de evento.
///
/// Uso en una pantalla:
/// ```dart
/// final _subs = <StreamSubscription>[];
///
/// @override
/// void initState() {
///   super.initState();
///   _subs.add(SocketService().on('event:created').listen((_) => _reload()));
/// }
///
/// @override
/// void dispose() {
///   for (final s in _subs) s.cancel();
///   super.dispose();
/// }
/// ```
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  /// StreamControllers broadcast por nombre de evento.
  /// Se crean la primera vez que una pantalla solicita el stream.
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  bool get isConnected => _socket?.connected ?? false;

  // ─── Conexión ────────────────────────────────────────────────────────────

  /// Inicializa y conecta el socket. Idempotente: si ya está conectado o
  /// inicializado no hace nada.
  void connect() {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    _socket = IO.io(
      Environment.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()   // conectamos manualmente después de registrar listeners
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(3000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('🔌 [Socket] Connected → ${Environment.socketUrl}');
      })
      ..onDisconnect((_) {
        debugPrint('🔌 [Socket] Disconnected');
      })
      ..onConnectError((e) {
        debugPrint('🔌 [Socket] Connect error: $e');
      })
      ..onError((e) {
        debugPrint('🔌 [Socket] Error: $e');
      });

    // Registrar todos los eventos y redirigirlos a sus streams
    for (final event in _kSocketEvents) {
      _socket!.on(event, (data) {
        final payload = (data is Map)
            ? Map<String, dynamic>.from(data as Map)
            : <String, dynamic>{};
        if (Environment.enableLogs) {
          debugPrint('📡 [Socket] $event → $payload');
        }
        _controllers[event]?.add(payload);
      });
    }

    _socket!.connect();
  }

  // ─── Streams ─────────────────────────────────────────────────────────────

  /// Devuelve un stream broadcast para el evento dado.
  /// El StreamController se crea la primera vez que se solicita.
  Stream<Map<String, dynamic>> on(String event) {
    _controllers.putIfAbsent(
      event,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    return _controllers[event]!.stream;
  }

  // ─── Ciclo de vida ───────────────────────────────────────────────────────

  /// Desconecta el socket (p. ej. cuando la app va al background).
  /// El cliente reconectará automáticamente al volver al foreground.
  void disconnect() {
    _socket?.disconnect();
  }
}
