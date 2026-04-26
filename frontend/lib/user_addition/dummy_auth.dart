import 'package:parkingapp/user_addition/user_model.dart';

const List<Map<String, dynamic>> _dummyUsers = [
  {
    'user_id': 1,
    'name': 'Emma',
    'lastname': 'Driver',
    'email': 'emma@parking.test',
    'password': 'password123',
    'access_token': 'dummy-token-emma',
    'vehicles': [
      {'vehicle_id': 101, 'registration': 'EM21 CAR', 'type': 'CAR'},
      {'vehicle_id': 102, 'registration': 'EV22 EM', 'type': 'EV'},
    ],
    'payment_methods': [
      {'type': 'Visa', 'last4': '4242', 'expiry': '12/26'},
      {'type': 'Mastercard', 'last4': '8888', 'expiry': '08/27'},
    ],
  },
  {
    'user_id': 2,
    'name': 'Liam',
    'lastname': 'Parker',
    'email': 'liam@parking.test',
    'password': 'password123',
    'access_token': 'dummy-token-liam',
    'vehicles': [
      {'vehicle_id': 201, 'registration': 'LM11 VAN', 'type': 'PCV'},
    ],
    'payment_methods': [
      {'type': 'Visa', 'last4': '1111', 'expiry': '05/28'},
    ],
  },
];

Future<AuthSession> loginDummyUser({
  required String email,
  required String password,
}) async {
  final normalisedEmail = email.trim().toLowerCase();
  final matchedUser = _dummyUsers.where(
    (user) => (user['email'] as String).toLowerCase() == normalisedEmail,
  );

  if (matchedUser.isEmpty) {
    throw Exception('No dummy account found for this email');
  }

  final user = matchedUser.first;
  if (user['password'] != password) {
    throw Exception('Invalid password for dummy account');
  }

  return AuthSession(
    userId: user['user_id'] as int,
    name: user['name'] as String,
    lastname: user['lastname'] as String,
    email: user['email'] as String,
    accessToken: user['access_token'] as String,
  );
}

Future<UserProfileResponse> getDummyUserProfile({required String email}) async {
  final normalisedEmail = email.trim().toLowerCase();
  final matchedUser = _dummyUsers.where(
    (user) => (user['email'] as String).toLowerCase() == normalisedEmail,
  );

  if (matchedUser.isEmpty) {
    throw Exception('Dummy profile not found');
  }

  final user = matchedUser.first;
  final vehicles = (user['vehicles'] as List<dynamic>)
      .map((vehicle) => UserVehicle.fromJson(vehicle as Map<String, dynamic>))
      .toList();

  return UserProfileResponse(
    userId: user['user_id'] as int,
    name: user['name'] as String,
    lastname: user['lastname'] as String,
    email: user['email'] as String,
    vehicles: vehicles,
  );
}

List<Map<String, String>> getDummyPaymentMethods({required String email}) {
  final normalisedEmail = email.trim().toLowerCase();
  final matchedUser = _dummyUsers.where(
    (user) => (user['email'] as String).toLowerCase() == normalisedEmail,
  );

  if (matchedUser.isEmpty) {
    return [];
  }

  final paymentMethods = matchedUser.first['payment_methods'] as List<dynamic>?;
  if (paymentMethods == null) {
    return [];
  }

  return paymentMethods
      .map(
        (method) => {
          'type': (method as Map<String, dynamic>)['type'] as String,
          'last4': method['last4'] as String,
          'expiry': method['expiry'] as String,
        },
      )
      .toList();
}
