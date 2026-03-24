import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkingapp/user_addition/user_model.dart';

Future<void> createUser({required CreateUserRequest request}) async {
  final uri = Uri.parse('http://127.0.0.1:8080/users');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(request.toJson()),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    // success
    return;
  } else {
    throw Exception(
      'Failed to create user: ${response.statusCode} ${response.body}',
    );
  }
}

Future<Map<String, dynamic>> loginUser({
  required String email,
  required String password,
}) async {
  final uri = Uri.parse('http://127.0.0.1:8080/login');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  final Map<String, dynamic> data = response.body.isNotEmpty
      ? jsonDecode(response.body) as Map<String, dynamic>
      : <String, dynamic>{};

  if (response.statusCode == 200 && data['result'] == true) {
    return data;
  }

  throw Exception(data['error']?.toString() ?? 'Login failed');
}
