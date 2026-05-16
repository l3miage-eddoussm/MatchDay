class User {
  final String firstName;
  final String lastName;
  final String email;
  final String passwordHash;


  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'passwordHash': passwordHash,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    firstName: json['firstName'],
    lastName: json['lastName'],
    email: json['email'],
    passwordHash: json['passwordHash'],
  );
}