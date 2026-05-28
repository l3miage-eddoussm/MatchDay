import 'package:cineart/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    final user = User(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      passwordHash: 'abc123',
    );

    test('toJson retourne les bonnes clés', () {
      final json = user.toJson();
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['email'], 'john@example.com');
      expect(json['passwordHash'], 'abc123');
    });

    test('fromJson reconstruit correctement', () {
      final json = user.toJson();
      final result = User.fromJson(json);
      expect(result.firstName, user.firstName);
      expect(result.lastName, user.lastName);
      expect(result.email, user.email);
      expect(result.passwordHash, user.passwordHash);
    });

    test('fromJson → toJson est idempotent', () {
      final json = user.toJson();
      expect(User.fromJson(json).toJson(), json);
    });
  });
}