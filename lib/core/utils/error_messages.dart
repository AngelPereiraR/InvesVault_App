import 'dart:io';
import 'package:dio/dio.dart';

/// Converts any thrown error into a user-friendly Spanish message.
String friendlyError(Object e) {
  if (e is DioException) {
    // ── Network / connectivity ────────────────────────────────────────────
    if (e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown && e.error is SocketException)) {
      return 'Sin conexión. Comprueba tu red e inténtalo de nuevo.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
    }
    if (e.type == DioExceptionType.cancel) {
      return 'La solicitud fue cancelada. Inténtalo de nuevo.';
    }

    // ── HTTP status codes ─────────────────────────────────────────────────
    final status = e.response?.statusCode;
    if (status != null) {
      final serverMsg = _extractServerMessage(e.response?.data);
      switch (status) {
        case 400:
          return serverMsg ??
              'Solicitud incorrecta. Revisa los datos e inténtalo de nuevo.';
        case 401:
          return 'Sesión expirada. Inicia sesión de nuevo.';
        case 403:
          return serverMsg ?? 'No tienes permiso para realizar esta acción.';
        case 404:
          return serverMsg ?? 'No se ha encontrado el recurso solicitado.';
        case 409:
          return serverMsg ?? 'Ya existe un elemento con esos datos.';
        case 422:
          return serverMsg ?? 'Los datos enviados no son válidos.';
        case 429:
          return 'Demasiadas solicitudes. Espera un momento e inténtalo de nuevo.';
        case 500:
          // Show a server-provided detail if it's not a generic phrase
          if (serverMsg != null &&
              !_isGenericServerPhrase(serverMsg)) {
            return 'Error del servidor: $serverMsg';
          }
          return 'Error interno del servidor. Inténtalo más tarde.';
        case 502:
          return 'El servidor no está disponible (502). Inténtalo más tarde.';
        case 503:
          return 'Servicio temporalmente no disponible. Inténtalo más tarde.';
        case 504:
          return 'El servidor tardó demasiado en responder (504). Inténtalo más tarde.';
        default:
          return serverMsg ??
              'Error inesperado (código $status). Inténtalo de nuevo.';
      }
    }

    // Unknown DioException with inner cause
    if (e.error != null) {
      return _fromInnerError(e.error!);
    }
  }

  // ── Non-Dio errors ────────────────────────────────────────────────────────
  if (e is SocketException) {
    return 'Sin conexión. Comprueba tu red e inténtalo de nuevo.';
  }
  if (e is HandshakeException) {
    return 'Error de seguridad en la conexión. Comprueba tu red e inténtalo de nuevo.';
  }
  if (e is FormatException) {
    return 'El servidor devolvió una respuesta inesperada. Inténtalo de nuevo.';
  }

  return _fromInnerError(e);
}

String _fromInnerError(Object e) {
  final raw = e.toString().toLowerCase();
  if (raw.contains('socketexception') || raw.contains('connection refused') ||
      raw.contains('network')) {
    return 'Sin conexión. Comprueba tu red e inténtalo de nuevo.';
  }
  if (raw.contains('timeout') || raw.contains('timed out')) {
    return 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
  }
  if (raw.contains('handshake') || raw.contains('certificate')) {
    return 'Error de seguridad en la conexión. Inténtalo de nuevo.';
  }
  // Strip common prefixes and return the remaining message
  return e
      .toString()
      .replaceFirst(RegExp(r'^(Exception|Error|DioException):\s*'), '');
}

bool _isGenericServerPhrase(String msg) {
  const generic = [
    'internal server error',
    'bad gateway',
    'service unavailable',
    'gateway timeout',
  ];
  final lower = msg.toLowerCase();
  return generic.any(lower.contains);
}

String? _extractServerMessage(dynamic data) {
  if (data is Map) {
    final msg = data['message'] ?? data['error'] ?? data['msg'] ??
        data['detail'] ?? data['details'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (msg is List && msg.isNotEmpty) return msg.first.toString();
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

