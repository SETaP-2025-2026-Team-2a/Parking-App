import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkingapp/user_addition/user_model.dart';

Future<void> createUser({
  required CreateUserRequest request,
}) async {
  final uri = Uri.parse('http://127.0.0.1:8080/users'); // Adjust the URL as needed

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer <token>', // if needed
    },
    body: jsonEncode({
      'username': request.name,
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