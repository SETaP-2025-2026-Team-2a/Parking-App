import 'dart:convert';

class Data {
  final List words;
  Data({required this.words});
  Data copyWith({List? words}) {
    return Data(words: words ?? this.words);
  }

  Map toMap() {
    return {'words': words};
  }

  factory Data.fromMap(Map map) {
    return Data(words: List.from((map['data'] as List)));
  }
  String toJson() => json.encode(toMap());
  factory Data.fromJson(String source) =>
      Data.fromMap(json.decode(source) as Map);
  @override
  String toString() => 'Data(words: $words)';
  @override
  // ignore: hash_and_equals
  int get hashCode => words.hashCode;
}
