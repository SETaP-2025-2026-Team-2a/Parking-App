import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:parkingapp/user_addition/user_model.dart';

const String _baseUrl = 'http://127.0.0.1:8080';

Future<bool> getUserByEmail({required String email}) async {
  final encodedEmail = Uri.encodeComponent(email.trim());
  final uri = Uri.parse('$_baseUrl/users/$encodedEmail');

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
  final uri = Uri.parse('$_baseUrl/signup');

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

Future<AuthSession> loginUser({
  required String email,
  required String password,
}) async {
  final uri = Uri.parse('$_baseUrl/login');

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  final body = response.body.isNotEmpty
      ? jsonDecode(response.body) as Map<String, dynamic>
      : <String, dynamic>{};

  if (response.statusCode == 200 && body['result'] == true) {
    return AuthSession.fromJson(body);
  }

  final message = (body['error'] as String?) ?? 'Invalid credentials';
  throw Exception(message);
}

Future<UserProfileResponse> getUserProfile({required String email}) async {
  final encodedEmail = Uri.encodeComponent(email.trim());
  final uri = Uri.parse('$_baseUrl/users/$encodedEmail');

  final response = await http.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  );

  final body = response.body.isNotEmpty
      ? jsonDecode(response.body) as Map<String, dynamic>
      : <String, dynamic>{};

  if (response.statusCode == 200 && body['result'] == true) {
    return UserProfileResponse.fromJson(body);
  }

  final message = (body['error'] as String?) ?? 'Could not load user profile';
  throw Exception(message);
}

Future<void> updateUserProfile({
  required String email,
  required String name,
  required String lastname,
  required String updatedEmail,
  required List<Map<String, String>> vehicles,
  required List<Map<String, String>> paymentMethods,
}) async {
  final encodedEmail = Uri.encodeComponent(email.trim());
  final uri = Uri.parse('$_baseUrl/users/$encodedEmail');

  final response = await http.put(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'lastname': lastname,
      'email': updatedEmail,
      'vehicles': vehicles,
      'payment_methods': paymentMethods,
    }),
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(
    'Failed to update user: ${response.statusCode} ${response.body}',
  );
}
