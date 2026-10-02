import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

enum PasswordManageAction { removed, changed }

class PasswordManageResult {
  final PasswordManageAction action;
  final String? newPassword;

  const PasswordManageResult({
    required this.action,
    this.newPassword,
  });
}

const List<String> kDefaultSecurityQuestions = [
  'Apa nama hewan peliharaan pertama Anda?',
  'Di kota apa Anda dilahirkan?',
  'Apa nama sekolah dasar (SD) Anda?',
  'Apa makanan favorit masa kecil Anda?',
  'Apa nama jalan tempat Anda tumbuh besar?',
  'Tulis pertanyaan sendiri...',
];

class PasswordDialog {
  /// Dialog to set a new password on a note or folder
  static Future<String?> showSetPassword(
    BuildContext context, {
    required String title,
    required String itemType, // 'Catatan' or 'Folder'
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SetPasswordDialog(
        title: title,
        itemType: itemType,
      ),
    );
  }

  /// Dialog to unlock a locked note or folder (includes Forgot Password / Recovery)
  static Future<bool> showUnlock(
    BuildContext context, {
    required String title,
    required String itemType, // 'Catatan' or 'Folder'
    required String correctPassword,
    void Function(String newPassword)? onPasswordChanged,
    VoidCallback? onPasswordRemoved,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _UnlockPasswordDialog(
        title: title,
        itemType: itemType,
        correctPassword: correctPassword,
        onPasswordChanged: onPasswordChanged,
        onPasswordRemoved: onPasswordRemoved,
      ),
    );
    return result ?? false;
  }

  /// Dialog / BottomSheet to manage existing password (Change, Remove, or Setup Security Question)
  static Future<PasswordManageResult?> showManagePassword(
    BuildContext context, {
    required String title,
    required String itemType,
    required String currentPassword,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ManagePasswordSheet(
        title: title,
        itemType: itemType,
      ),
    );

    if (choice == null || !context.mounted) return null;

    if (choice == 'remove') {
      final verified = await showUnlock(
        context,
        title: title,
        itemType: itemType,
        correctPassword: currentPassword,
      );
      if (verified) {
        return const PasswordManageResult(
          action: PasswordManageAction.removed,
        );
      }
    } else if (choice == 'change') {
      final newPass = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ChangePasswordDialog(
          title: title,
          itemType: itemType,
          currentPassword: currentPassword,
        ),
      );
      if (newPass != null) {
        return PasswordManageResult(
          action: PasswordManageAction.changed,
          newPassword: newPass,
        );
      }
    } else if (choice == 'security_question') {
      await showSetupSecurityQuestion(context);
    }
    return null;
  }

  /// Dialog to setup or change security question for password recovery
  static Future<bool?> showSetupSecurityQuestion(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _SecurityQuestionSetupDialog(),
    );
  }
}

// -------------------------------------------------------------
// 1. SET PASSWORD DIALOG
// -------------------------------------------------------------
class _SetPasswordDialog extends StatefulWidget {
  final String title;
  final String itemType;

  const _SetPasswordDialog({
    required this.title,
    required this.itemType,
  });

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _storageService = StorageService();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _customQuestionController = TextEditingController();
  final _answerController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  bool _hasExistingSecurityQuestion = false;
  bool _showSecurityQuestionSetup = false;
  String _selectedQuestion = kDefaultSecurityQuestions[0];
  bool _isCustomQuestion = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityQuestion();
  }

  void _checkSecurityQuestion() async {
    final hasQ = await _storageService.hasSecurityQuestion();
    if (mounted) {
      setState(() {
        _hasExistingSecurityQuestion = hasQ;
        _showSecurityQuestionSetup = !hasQ; // Auto show if not set yet
      });
    }
  }

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    _customQuestionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _submit() async {
    final pass = _passController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.isEmpty) {
      setState(() {
        _errorMessage = 'Kata sandi tidak boleh kosong';
      });
      return;
    }

    if (pass.length < 4) {
      setState(() {
        _errorMessage = 'Kata sandi minimal 4 karakter / angka';
      });
      return;
    }

    if (pass != confirm) {
      setState(() {
        _errorMessage = 'Konfirmasi kata sandi tidak cocok';
      });
      return;
    }

    // If security question is being configured
    if (_showSecurityQuestionSetup) {
      final question = _isCustomQuestion
          ? _customQuestionController.text.trim()
          : _selectedQuestion.trim();
      final answer = _answerController.text.trim();

      if (answer.isNotEmpty) {
        if (_isCustomQuestion && question.isEmpty) {
          setState(() {
            _errorMessage = 'Pertanyaan keamanan kustom wajib diisi';
          });
          return;
        }
        await _storageService.saveSecurityQuestion(question, answer);
      }
    }

    HapticFeedback.lightImpact();
    if (mounted) {
      Navigator.of(context).pop(pass);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon badge
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF4F46E5),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Kunci ${widget.itemType}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tetapkan kata sandi untuk mengamankan data ${widget.itemType.toLowerCase()} "${widget.title.isEmpty ? widget.itemType : widget.title}".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Input: Password
                TextField(
                  controller: _passController,
                  autofocus: true,
                  obscureText: _obscurePass,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi Baru',
                    hintText: 'Minimal 4 karakter',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                  },
                ),
                const SizedBox(height: 12),

                // Input: Confirm Password
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi',
                    hintText: 'Ulangi kata sandi baru',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                  },
                ),

                const SizedBox(height: 16),

                // Recovery / Security Question Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            size: 18,
                            color: Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Pemulihan Jika Lupa Kata Sandi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (_hasExistingSecurityQuestion)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showSecurityQuestionSetup = !_showSecurityQuestionSetup;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _showSecurityQuestionSetup ? 'Tutup' : 'Ubah',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_hasExistingSecurityQuestion && !_showSecurityQuestionSetup) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Pertanyaan keamanan sudah aktif di aplikasi.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_showSecurityQuestionSetup) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Pilih pertanyaan keamanan:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQuestion,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                              items: kDefaultSecurityQuestions.map((q) {
                                return DropdownMenuItem<String>(
                                  value: q,
                                  child: Text(
                                    q,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedQuestion = val;
                                    _isCustomQuestion = val == 'Tulis pertanyaan sendiri...';
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        if (_isCustomQuestion) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customQuestionController,
                            decoration: InputDecoration(
                              labelText: 'Pertanyaan Kustom',
                              hintText: 'Misal: Nama kota kencan pertama?',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextField(
                          controller: _answerController,
                          decoration: InputDecoration(
                            labelText: 'Jawaban Keamanan',
                            hintText: 'Masukkan jawaban Anda',
                            prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 22),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Pasang Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. UNLOCK PASSWORD DIALOG (With Forgot Password button)
// -------------------------------------------------------------
class _UnlockPasswordDialog extends StatefulWidget {
  final String title;
  final String itemType;
  final String correctPassword;
  final void Function(String newPassword)? onPasswordChanged;
  final VoidCallback? onPasswordRemoved;

  const _UnlockPasswordDialog({
    required this.title,
    required this.itemType,
    required this.correctPassword,
    this.onPasswordChanged,
    this.onPasswordRemoved,
  });

  @override
  State<_UnlockPasswordDialog> createState() => _UnlockPasswordDialogState();
}

class _UnlockPasswordDialogState extends State<_UnlockPasswordDialog> {
  final _passController = TextEditingController();
  bool _obscurePass = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  void _verify() {
    final pass = _passController.text.trim();
    if (pass.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan kata sandi';
      });
      return;
    }

    if (pass == widget.correctPassword) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Kata sandi salah. Silakan coba lagi.';
      });
      _passController.clear();
    }
  }

  void _openForgotPassword() async {
    final recovered = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PasswordRecoveryDialog(
        title: widget.title,
        itemType: widget.itemType,
        correctPassword: widget.correctPassword,
        onPasswordChanged: widget.onPasswordChanged,
        onPasswordRemoved: widget.onPasswordRemoved,
      ),
    );

    if (recovered == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shield Lock Icon
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  '${widget.itemType} Terkunci',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan kata sandi untuk membuka ${widget.itemType.toLowerCase()} "${widget.title.isEmpty ? widget.itemType : widget.title}".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Input: Password
                TextField(
                  controller: _passController,
                  autofocus: true,
                  obscureText: _obscurePass,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    hintText: 'Masukkan kata sandi',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onSubmitted: (_) => _verify(),
                  onChanged: (_) {
                    if (_errorMessage != null) setState(() => _errorMessage = null);
                  },
                ),

                // Forgot Password link button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _openForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      size: 15,
                      color: Color(0xFF4F46E5),
                    ),
                    label: const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Buka Kunci',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. PASSWORD RECOVERY / FORGOT PASSWORD DIALOG
// -------------------------------------------------------------
class _PasswordRecoveryDialog extends StatefulWidget {
  final String title;
  final String itemType;
  final String correctPassword;
  final void Function(String newPassword)? onPasswordChanged;
  final VoidCallback? onPasswordRemoved;

  const _PasswordRecoveryDialog({
    required this.title,
    required this.itemType,
    required this.correctPassword,
    this.onPasswordChanged,
    this.onPasswordRemoved,
  });

  @override
  State<_PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<_PasswordRecoveryDialog> {
  final _storageService = StorageService();
  final _answerController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = true;
  String? _securityQuestion;
  bool _isVerified = false;
  bool _isResetMode = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestion();
  }

  void _loadSecurityQuestion() async {
    final question = await _storageService.getSecurityQuestion();
    if (mounted) {
      setState(() {
        _securityQuestion = question;
        _isLoading = false;
        // If no question was ever set, let the user recover directly to avoid lockouts
        if (question == null || question.isEmpty) {
          _isVerified = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _verifyAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() => _errorMessage = 'Masukkan jawaban keamanan Anda');
      return;
    }

    final isValid = await _storageService.verifySecurityAnswer(answer);
    if (isValid) {
      HapticFeedback.lightImpact();
      setState(() {
        _isVerified = true;
        _errorMessage = null;
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Jawaban keamanan tidak cocok. Coba lagi.';
      });
    }
  }

  void _submitNewPassword() async {
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Kolom kata sandi tidak boleh kosong');
      return;
    }

    if (newPass.length < 4) {
      setState(() => _errorMessage = 'Kata sandi minimal 4 karakter');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Konfirmasi kata sandi tidak cocok');
      return;
    }

    HapticFeedback.lightImpact();
    widget.onPasswordChanged?.call(newPass);
    Navigator.of(context).pop(true);
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: widget.correctPassword));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Kata sandi berhasil disalin ke papan klip'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: SingleChildScrollView(
            child: _isResetMode
                ? _buildResetPasswordView()
                : (_isVerified ? _buildVerifiedSuccessView() : _buildAnswerQuestionView()),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerQuestionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.help_center_rounded,
              color: Color(0xFF4F46E5),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Pemulihan Kata Sandi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Jawab pertanyaan keamanan berikut untuk memverifikasi kepemilikan ${widget.itemType.toLowerCase()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // Security Question Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.quiz_rounded,
                size: 20,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pertanyaan Keamanan:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _securityQuestion ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Answer input
        TextField(
          controller: _answerController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Jawaban Anda',
            hintText: 'Masukkan jawaban keamanan...',
            prefixIcon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onSubmitted: (_) => _verifyAnswer(),
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _verifyAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Verifikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifiedSuccessView() {
    final bool hasQ = _securityQuestion != null && _securityQuestion!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hasQ ? 'Verifikasi Berhasil! 🎉' : 'Pemulihan Akses Data',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasQ
              ? 'Akses ke ${widget.itemType.toLowerCase()} "${widget.title}" berhasil dipulihkan. Berikut kata sandi Anda:'
              : 'Pertanyaan keamanan belum pernah diatur. Anda dapat melihat kata sandi, membuka kunci langsung, atau mengatur ulang kata sandi:',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        // Password Display Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.key_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kata Sandi Anda:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showPassword ? widget.correctPassword : ('•' * widget.correctPassword.length),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: const Color(0xFF92400E),
                ),
                tooltip: _showPassword ? 'Sembunyikan' : 'Tampilkan',
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 20,
                  color: Color(0xFF92400E),
                ),
                tooltip: 'Salin Kata Sandi',
                onPressed: _copyPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action 1: Open/Unlock directly
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.lock_open_rounded, size: 18),
          label: const Text('Buka Kunci Sekarang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),

        // Action 2: Reset / Change Password
        OutlinedButton.icon(
          onPressed: () => setState(() => _isResetMode = true),
          icon: const Icon(Icons.password_rounded, size: 18, color: Color(0xFF4F46E5)),
          label: const Text(
            'Ubah / Atur Ulang Kata Sandi',
            style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: Color(0xFFC7D2FE)),
          ),
        ),

        // Action 3: Remove password protection (if callback provided)
        if (widget.onPasswordRemoved != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              widget.onPasswordRemoved?.call();
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
            label: const Text(
              'Hapus Kunci Kata Sandi',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResetPasswordView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF4F46E5),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Atur Ulang Kata Sandi',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan kata sandi baru untuk ${widget.itemType.toLowerCase()} "${widget.title}".',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),

        TextField(
          controller: _newPassController,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Kata Sandi Baru',
            hintText: 'Minimal 4 karakter',
            prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPassController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Konfirmasi Kata Sandi Baru',
            hintText: 'Ulangi kata sandi baru',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onSubmitted: (_) => _submitNewPassword(),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _isResetMode = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 4. MANAGE PASSWORD SHEET (Change, Remove, or Security Question)
// -------------------------------------------------------------
class _ManagePasswordSheet extends StatelessWidget {
  final String title;
  final String itemType;

  const _ManagePasswordSheet({
    required this.title,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Kata Sandi $itemType',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        title.isEmpty ? itemType : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Option 1: Ubah Password
            ListTile(
              leading: const Icon(Icons.password_rounded, color: Color(0xFF4F46E5)),
              title: const Text(
                'Ubah Kata Sandi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              subtitle: const Text(
                'Ganti kata sandi dengan yang baru',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () => Navigator.of(context).pop('change'),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Option 2: Pertanyaan Pemulihan
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined, color: Color(0xFF0284C7)),
              title: const Text(
                'Pertanyaan Pemulihan (Lupa Password)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              subtitle: const Text(
                'Atur pertanyaan keamanan pemulihan kata sandi',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () => Navigator.of(context).pop('security_question'),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // Option 3: Hapus Password (Buka Kunci Permanen)
            ListTile(
              leading: const Icon(Icons.lock_open_rounded, color: Color(0xFFEF4444)),
              title: const Text(
                'Hapus Kunci Kata Sandi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
              ),
              subtitle: const Text(
                'Hapus perlindungan kata sandi dari item ini',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () => Navigator.of(context).pop('remove'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. CHANGE PASSWORD DIALOG
// -------------------------------------------------------------
class _ChangePasswordDialog extends StatefulWidget {
  final String title;
  final String itemType;
  final String currentPassword;

  const _ChangePasswordDialog({
    required this.title,
    required this.itemType,
    required this.currentPassword,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _submit() {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() {
        _errorMessage = 'Semua kolom wajib diisi';
      });
      return;
    }

    if (oldPass != widget.currentPassword) {
      setState(() {
        _errorMessage = 'Kata sandi lama tidak sesuai';
      });
      return;
    }

    if (newPass.length < 4) {
      setState(() {
        _errorMessage = 'Kata sandi baru minimal 4 karakter';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _errorMessage = 'Konfirmasi kata sandi baru tidak cocok';
      });
      return;
    }

    HapticFeedback.lightImpact();
    Navigator.of(context).pop(newPass);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: Color(0xFF4F46E5),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Kata Sandi ${widget.itemType}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 18),

              // Old Password
              TextField(
                controller: _oldPassController,
                autofocus: true,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Lama',
                  prefixIcon: const Icon(Icons.lock_clock_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // New Password
              TextField(
                controller: _newPassController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Confirm New Password
              TextField(
                controller: _confirmPassController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                onSubmitted: (_) => _submit(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 6. STANDALONE SECURITY QUESTION SETUP DIALOG
// -------------------------------------------------------------
class _SecurityQuestionSetupDialog extends StatefulWidget {
  const _SecurityQuestionSetupDialog();

  @override
  State<_SecurityQuestionSetupDialog> createState() => _SecurityQuestionSetupDialogState();
}

class _SecurityQuestionSetupDialogState extends State<_SecurityQuestionSetupDialog> {
  final _storageService = StorageService();
  final _customQuestionController = TextEditingController();
  final _answerController = TextEditingController();

  String _selectedQuestion = kDefaultSecurityQuestions[0];
  bool _isCustomQuestion = false;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() async {
    final existingQ = await _storageService.getSecurityQuestion();
    if (mounted) {
      setState(() {
        if (existingQ != null && existingQ.isNotEmpty) {
          if (kDefaultSecurityQuestions.contains(existingQ)) {
            _selectedQuestion = existingQ;
            _isCustomQuestion = false;
          } else {
            _selectedQuestion = 'Tulis pertanyaan sendiri...';
            _isCustomQuestion = true;
            _customQuestionController.text = existingQ;
          }
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _customQuestionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _save() async {
    final question = _isCustomQuestion
        ? _customQuestionController.text.trim()
        : _selectedQuestion.trim();
    final answer = _answerController.text.trim();

    if (_isCustomQuestion && question.isEmpty) {
      setState(() => _errorMessage = 'Pertanyaan kustom tidak boleh kosong');
      return;
    }

    if (answer.isEmpty) {
      setState(() => _errorMessage = 'Jawaban keamanan tidak boleh kosong');
      return;
    }

    await _storageService.saveSecurityQuestion(question, answer);
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Pertanyaan pemulihan berhasil disimpan'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Color(0xFF4F46E5),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pertanyaan Pemulihan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pertanyaan ini digunakan untuk memulihkan kata sandi jika Anda lupa kata sandi catatan atau folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Question selection dropdown
                const Text(
                  'Pilih Pertanyaan Keamanan:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedQuestion,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                      items: kDefaultSecurityQuestions.map((q) {
                        return DropdownMenuItem<String>(
                          value: q,
                          child: Text(
                            q,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedQuestion = val;
                            _isCustomQuestion = val == 'Tulis pertanyaan sendiri...';
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_isCustomQuestion) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customQuestionController,
                    decoration: InputDecoration(
                      labelText: 'Pertanyaan Kustom',
                      hintText: 'Tulis pertanyaan unik Anda...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Answer
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Jawaban Anda',
                    hintText: 'Masukkan jawaban Anda...',
                    prefixIcon: const Icon(Icons.edit_note_rounded, size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _save(),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
