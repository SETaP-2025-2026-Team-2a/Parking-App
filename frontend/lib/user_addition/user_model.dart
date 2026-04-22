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
