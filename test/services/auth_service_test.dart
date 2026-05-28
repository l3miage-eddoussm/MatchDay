import 'package:cineart/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_storage_service.dart';

void main() {
  late AuthService auth;
  late FakeStorageService fakeStorage;

  setUp(() {
    fakeStorage = FakeStorageService();
    auth = AuthService.withStorage(fakeStorage);
  });

  group('AuthService - register', () {
    test('enregistre un nouvel utilisateur', () async {
      await auth.register(
        firstName: 'John', lastName: 'Doe',
        email: 'john@example.com', password: 'secret123',
      );
      final user = await auth.login(email: 'john@example.com', password: 'secret123');
      expect(user.email, 'john@example.com');
      expect(user.firstName, 'John');
    });

    test('exception si email déjà utilisé', () async {
      await auth.register(
        firstName: 'John', lastName: 'Doe',
        email: 'john@example.com', password: 'secret123',
      );
      expect(
            () => auth.register(
          firstName: 'Jane', lastName: 'Doe',
          email: 'john@example.com', password: 'other',
        ),
        throwsException,
      );
    });

    test('plusieurs utilisateurs peuvent s\'enregistrer', () async {
      await auth.register(firstName: 'A', lastName: 'A', email: 'a@a.com', password: '111');
      await auth.register(firstName: 'B', lastName: 'B', email: 'b@b.com', password: '222');
      final user = await auth.login(email: 'b@b.com', password: '222');
      expect(user.firstName, 'B');
    });
  });

  group('AuthService - login', () {
    setUp(() async {
      await auth.register(
        firstName: 'John', lastName: 'Doe',
        email: 'john@example.com', password: 'secret123',
      );
    });

    test('login réussi retourne le bon User', () async {
      final user = await auth.login(email: 'john@example.com', password: 'secret123');
      expect(user.email, 'john@example.com');
      expect(user.lastName, 'Doe');
    });

    test('mauvais mot de passe → exception', () {
      expect(
            () => auth.login(email: 'john@example.com', password: 'wrong'),
        throwsException,
      );
    });

    test('email inexistant → exception', () {
      expect(
            () => auth.login(email: 'nobody@example.com', password: 'secret123'),
        throwsException,
      );
    });

    test('mot de passe jamais stocké en clair', () async {
      await auth.login(email: 'john@example.com', password: 'secret123');
      final stored = fakeStorage.getItem('cineart_users') as String;
      expect(stored, isNot(contains('secret123')));
    });
  });

  group('AuthService - getCurrentUser', () {
    test('retourne null si pas connecté', () async {
      expect(await auth.getCurrentUser(), isNull);
    });

    test('retourne le user après login', () async {
      await auth.register(firstName: 'John', lastName: 'Doe', email: 'j@j.com', password: 'pass');
      await auth.login(email: 'j@j.com', password: 'pass');
      final user = await auth.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.email, 'j@j.com');
    });
  });

  group('AuthService - logout', () {
    test('getCurrentUser retourne null après logout', () async {
      await auth.register(firstName: 'John', lastName: 'Doe', email: 'j@j.com', password: 'pass');
      await auth.login(email: 'j@j.com', password: 'pass');
      await auth.logout();
      expect(await auth.getCurrentUser(), isNull);
    });
  });
}