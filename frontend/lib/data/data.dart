import 'dart:convert';

class Data {
  final List data;
  Data({required this.data});
  Data copyWith({List? data}) {
    return Data(data: data ?? this.data);
  }

  Map toMap() {
    return {'data': data};
  }

  factory Data.fromMap(Map map) {
    return Data(data: List.from((map['data'] as List)));
  }
  String toJson() => json.encode(toMap());
  factory Data.fromJson(String source) =>
      Data.fromMap(json.decode(source) as Map);
  @override
  String toString() => 'Data(data: $data)';
  @override
  // ignore: hash_and_equals
  int get hashCode => data.hashCode;
}
