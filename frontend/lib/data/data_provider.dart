part of 'cubit.dart';
class DataDataProvider {
  static Future fetch() async {
    final request = await http.get(Uri.parse('http://127.0.0.1:8080/'));
    if (request.statusCode == 200) {
      return Data.fromJson(request.body);
    } else {
      throw Exception("Server returned status code: ${request.statusCode}");
    }
  }
}
