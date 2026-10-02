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
      expect(textFields, findsNWidgets(3));

      // Enter password & recovery answer
      await tester.enterText(textFields.at(0), '1234');
      await tester.enterText(textFields.at(1), '1234');
      await tester.enterText(textFields.at(2), 'kucing');
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Pasang Password'));
      await tester.pumpAndSettle();
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

    testWidgets('PasswordDialog.showManagePassword allows removing password after verifying', (WidgetTester tester) async {
      PasswordManageResult? manageResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  manageResult = await PasswordDialog.showManagePassword(
                    ctx,
                    title: 'Dokumen',
                    itemType: 'Catatan',
                    currentPassword: 'current_pass_123',
                  );
                },
                child: const Text('Open Manage Password'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Manage Password'));
      await tester.pumpAndSettle();

      // Check sheet options
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Hapus Kunci Kata Sandi'), findsOneWidget);

      // Tap Hapus Kunci Kata Sandi
      await tester.tap(find.text('Hapus Kunci Kata Sandi'));
      await tester.pumpAndSettle();

      // Unlock verification dialog should be shown
      expect(find.text('Catatan Terkunci'), findsOneWidget);

      // Enter correct password
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'current_pass_123');
      await tester.tap(find.text('Buka Kunci'));
      await tester.pumpAndSettle();

      expect(manageResult, isNotNull);
      expect(manageResult!.action, PasswordManageAction.removed);
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

    testWidgets('Removing password from locked note un-locks the note in HomeScreen', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'is_app_initialized_v2': true,
      });
      final storage = StorageService();
      final now = DateTime.now();
      final lockedNote = NoteModel(
        id: 'note_locked_1',
        title: 'Rahasia Perusahaan',
        contentJson: '[{"insert":"Data Confidential\\n"}]',
        plainText: 'Data Confidential',
        createdAt: now,
        updatedAt: now,
        isLocked: true,
        password: 'mypassword',
      );

      await storage.saveNotes([lockedNote]);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Note has lock badge and masked preview
      expect(find.text('Terkunci'), findsOneWidget);
      expect(find.text('Catatan ini dilindungi kata sandi'), findsOneWidget);

      // Long press locked note
      await tester.longPress(find.text('Rahasia Perusahaan'));
      await tester.pumpAndSettle();

      expect(find.text('Kelola Kata Sandi (Password)'), findsOneWidget);
      await tester.tap(find.text('Kelola Kata Sandi (Password)'));
      await tester.pumpAndSettle();

      // Tap Hapus Kunci Kata Sandi
      expect(find.text('Hapus Kunci Kata Sandi'), findsOneWidget);
      await tester.tap(find.text('Hapus Kunci Kata Sandi'));
      await tester.pumpAndSettle();

      // Enter password in unlock dialog
      final textField = find.byType(TextField).last;
      await tester.enterText(textField, 'mypassword');
      await tester.tap(find.text('Buka Kunci'));
      await tester.pumpAndSettle();

      // Now note is unlocked: no "Terkunci" badge, content preview is visible!
      expect(find.text('Terkunci'), findsNothing);
      expect(find.text('Data Confidential'), findsOneWidget);
    });
  });
}
