import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/folder_model.dart';
import 'package:notes_app/models/note_model.dart';
import 'package:notes_app/screens/home_screen.dart';
import 'package:notes_app/services/storage_service.dart';
import 'package:notes_app/widgets/note_card.dart';
import 'package:notes_app/widgets/password_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Password lock models serialization test', () {
    test('FolderModel serializes and deserializes isLocked and password', () {
      final now = DateTime.now();
      final folder = FolderModel(
        id: 'f_locked_1',
        name: 'Dokumen Rahasia',
        colorValue: 0xFF4F46E5,
        createdAt: now,
        isLocked: true,
        password: 'secret_pin_123',
      );

      final map = folder.toMap();
      expect(map['isLocked'], isTrue);
      expect(map['password'], 'secret_pin_123');

      final fromMap = FolderModel.fromMap(map);
      expect(fromMap.isLocked, isTrue);
      expect(fromMap.password, 'secret_pin_123');
    });

    test('NoteModel serializes and deserializes isLocked and password', () {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'n_locked_1',
        title: 'Catatan Keuangan Pribadi',
        contentJson: '[{"insert":"Data Rahasia\\n"}]',
        plainText: 'Data Rahasia',
        createdAt: now,
        updatedAt: now,
        isLocked: true,
        password: 'secure_password_99',
      );

      final map = note.toMap();
      expect(map['isLocked'], isTrue);
      expect(map['password'], 'secure_password_99');

      final fromMap = NoteModel.fromMap(map);
      expect(fromMap.isLocked, isTrue);
      expect(fromMap.password, 'secure_password_99');
    });
  });

  group('NoteCard locked display test', () {
    testWidgets('NoteCard shows lock badge and masks content when note is locked', (WidgetTester tester) async {
      final now = DateTime.now();
      final note = NoteModel(
        id: 'n_test_1',
        title: 'Akun Bank',
        contentJson: '[{"insert":"PIN: 123456\\n"}]',
        plainText: 'PIN: 123456',
        createdAt: now,
        updatedAt: now,
        isLocked: true,
        password: 'pass',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteCard(
              note: note,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title is visible
      expect(find.text('Akun Bank'), findsOneWidget);
      // Check lock badge is visible
      expect(find.text('Terkunci'), findsOneWidget);
      // Check plain text is masked
      expect(find.text('Catatan ini dilindungi kata sandi'), findsOneWidget);
      expect(find.text('PIN: 123456'), findsNothing);
    });
  });

  group('PasswordDialog Widget Tests', () {
    testWidgets('PasswordDialog.showSetPassword validates and returns new password', (WidgetTester tester) async {
      String? resultPassword;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  resultPassword = await PasswordDialog.showSetPassword(
                    ctx,
                    title: 'Buku Harian',
                    itemType: 'Catatan',
                  );
                },
                child: const Text('Open Set Password'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Set Password'));
      await tester.pumpAndSettle();

      expect(find.text('Kunci Catatan'), findsOneWidget);

      // Find password input fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Enter password
      await tester.enterText(textFields.at(0), '1234');
      await tester.enterText(textFields.at(1), '1234');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Pasang Password'));
      await tester.pumpAndSettle();

      expect(resultPassword, '1234');
    });

    testWidgets('PasswordDialog.showUnlock verifies correct and wrong password', (WidgetTester tester) async {
      bool? unlockResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  unlockResult = await PasswordDialog.showUnlock(
                    ctx,
                    title: 'Folder Privat',
                    itemType: 'Folder',
                    correctPassword: 'secret_code',
                  );
                },
                child: const Text('Open Unlock'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Folder Terkunci'), findsOneWidget);

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter wrong password
      await tester.enterText(textField, 'wrong_pass');
      await tester.tap(find.text('Buka Kunci'));
      await tester.pumpAndSettle();

      // Shows error message
      expect(find.text('Kata sandi salah. Silakan coba lagi.'), findsOneWidget);

      // Enter correct password
      await tester.enterText(textField, 'secret_code');
      await tester.tap(find.text('Buka Kunci'));
      await tester.pumpAndSettle();

      expect(unlockResult, isTrue);
    });
  });

  group('HomeScreen password lock integration test', () {
    testWidgets('Long-pressing Note displays Kunci Catatan (Password) option in bottom sheet', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'is_app_initialized_v2': true,
      });
      final storage = StorageService();
      final now = DateTime.now();
      final note = NoteModel(
        id: 'note_demo_1',
        title: 'Ide Bisnis Baru',
        contentJson: '[{"insert":"Rahasia\\n"}]',
        plainText: 'Rahasia',
        createdAt: now,
        updatedAt: now,
      );

      await storage.saveNotes([note]);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find note card
      final noteCard = find.text('Ide Bisnis Baru');
      expect(noteCard, findsOneWidget);

      // Long press note
      await tester.longPress(noteCard);
      await tester.pumpAndSettle();

      // Check option exists
      expect(find.text('Kunci Catatan (Password)'), findsOneWidget);
    });
  });
}
