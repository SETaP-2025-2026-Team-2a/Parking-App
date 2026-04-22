import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkingapp/user_addition/user_model.dart';

Future<bool> getUserByEmail({required String email}) async {
  final encodedEmail = Uri.encodeComponent(email.trim());
  final uri = Uri.parse('http://127.0.0.1:8080/users/$encodedEmail');

  final response = await http.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    return true;
  }

  if (response.statusCode == 404) {
    return false;
  }

  throw Exception(
    'Failed to get user: ${response.statusCode} ${response.body}',
  );
}

Future<void> createUser({required CreateUserRequest request}) async {
  final uri = Uri.parse('http://127.0.0.1:8080/signup');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer <token>', // if needed
    },
    body: jsonEncode({
      'name': request.name,
      'lastname': request.lastname,
      'email': request.email,
      'password': request.password,
    }),
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
