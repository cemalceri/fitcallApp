typedef FromJsonObj<T> = T Function(Map<String, dynamic> json);
typedef FromJsonAny<T> = T Function(dynamic json);

class ApiResult<T> {
  final String mesaj;
  final T? data;
  ApiResult({required this.mesaj, this.data});
}

/// Basit parse yardımcıları
class ApiParsing {
  /// Tekil obje parse: json -> T
  static T parseObject<T>(dynamic json, FromJsonObj<T> fromJson) {
    return fromJson((json as Map).cast<String, dynamic>());
  }

  static List<T> parseList<T>(dynamic json, FromJsonObj<T> itemFromJson) {
    final list = (json as List);
    return list
        .map((e) => itemFromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
