class CreateUserRequest {
  final String name;
  final String lastname;
  final String email;
  final String password;

  CreateUserRequest({
    required this.name,
    this.lastname = '',
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'lastname': lastname,
    'email': email,
    'password': password,
  };
}

class AuthSession {
  final int userId;
  final String name;
  final String lastname;
  final String email;
  final String accessToken;

  AuthSession({
    required this.userId,
    required this.name,
    required this.lastname,
    required this.email,
    required this.accessToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['user_id'] as int,
      name: (json['name'] ?? '') as String,
      lastname: (json['lastname'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      accessToken: (json['access_token'] ?? '') as String,
    );
  }
}

class UserVehicle {
  final int vehicleId;
  final String registration;
  final String type;

  UserVehicle({
    required this.vehicleId,
    required this.registration,
    required this.type,
  });

  factory UserVehicle.fromJson(Map<String, dynamic> json) {
    return UserVehicle(
      vehicleId: json['vehicle_id'] as int,
      registration: (json['registration'] ?? '') as String,
      type: (json['type'] ?? '') as String,
    );
  }
}

class UserProfileResponse {
  final int userId;
  final String name;
  final String lastname;
  final String email;
  final List<UserVehicle> vehicles;

  UserProfileResponse({
    required this.userId,
    required this.name,
    required this.lastname,
    required this.email,
    required this.vehicles,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final vehiclesJson = (json['vehicles'] as List<dynamic>? ?? []);
    return UserProfileResponse(
      userId: json['user_id'] as int,
      name: (json['name'] ?? '') as String,
      lastname: (json['lastname'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      vehicles: vehiclesJson
          .map((vehicle) => UserVehicle.fromJson(vehicle as Map<String, dynamic>))
          .toList(),
    );
  }
}
