/// Utilitários de formatação/parsing para contratos da API.
class ApiFormat {
  ApiFormat._();

  /// Parse seguro de decimal vindo do backend.
  ///
  /// O backend costuma serializar Decimal como string (ex: "560.00").
  static double parseDecimal(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();

    final s = value.toString().trim();
    if (s.isEmpty) return fallback;

    // Aceita vírgula caso venha de algum lugar inesperado.
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }

  /// Formata `double` para string decimal com 2 casas, como o backend espera.
  static String formatDecimal(num value) => value.toStringAsFixed(2);

  /// Formata `DateTime` para YYYY-MM-DD (contrato de date fields do DRF).
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
