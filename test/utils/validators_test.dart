import 'package:flutter_test/flutter_test.dart';

import 'package:cyphlab_expense_tracker/utils/validators.dart';

void main() {
  group('Validators.title', () {
    test('rejects empty and whitespace', () {
      expect(Validators.title(null), isNotNull);
      expect(Validators.title('   '), isNotNull);
    });

    test('rejects titles over the max length', () {
      expect(Validators.title('a' * 51), isNotNull);
    });

    test('accepts a normal title', () {
      expect(Validators.title('Groceries'), isNull);
    });
  });

  group('Validators.amount', () {
    test('rejects empty, non-numeric and negative input', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });

    test('rejects zero, too many decimals and too large', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('10.123'), isNotNull);
      expect(Validators.amount('20000000'), isNotNull);
    });

    test('accepts valid amounts including thousands separators', () {
      expect(Validators.amount('250'), isNull);
      expect(Validators.amount('99.9'), isNull);
      expect(Validators.amount('1,250.50'), isNull);
    });

    test('parseAmount strips separators', () {
      expect(Validators.parseAmount(' 1,250.50 '), 1250.5);
    });
  });

  group('Validators.note', () {
    test('allows empty and rejects over max length', () {
      expect(Validators.note(null), isNull);
      expect(Validators.note(''), isNull);
      expect(Validators.note('a' * 201), isNotNull);
    });
  });

  group('Auth validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('user@example.com'), isNull);
    });

    test('password', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirmPassword', () {
      expect(Validators.confirmPassword('', 'secret1'), isNotNull);
      expect(Validators.confirmPassword('secret2', 'secret1'), isNotNull);
      expect(Validators.confirmPassword('secret1', 'secret1'), isNull);
    });
  });
}
