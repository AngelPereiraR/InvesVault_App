class Validators {
  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es obligatorio.';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Introduce un email válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'El valor'}) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio.';
    final n = double.tryParse(value.trim());
    if (n == null) return '$field debe ser un número.';
    if (n < 0) return '$field debe ser mayor o igual a 0.';
    return null;
  }
}
