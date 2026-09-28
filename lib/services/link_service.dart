import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkService {
  /// Regex pattern to detect URLs starting with http://, https://, www., or valid domain names
  static final RegExp urlRegex = RegExp(
    r'(https?:\/\/[^\s<>()]+|www\.[^\s<>()]+|(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+(?:com|org|net|edu|gov|io|id|dev|co|app|me|info|biz|tech|xyz|site|online|store|club|vip|live|top|pro|tv|cc|link|ai|gg|so|fm|page|wiki)(?:\/[^\s<>()]*)?)',
    caseSensitive: false,
  );

  /// Cleans trailing punctuations and prepends https:// if scheme is missing
  static String normalizeUrl(String rawUrl) {
    var url = rawUrl.trim();
    while (url.isNotEmpty &&
        (url.endsWith('.') ||
            url.endsWith(',') ||
            url.endsWith(';') ||
            url.endsWith('!') ||
            url.endsWith('?') ||
            url.endsWith(')'))) {
      if (url.endsWith(')') && url.contains('(')) break;
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))) {
      return 'https://$url';
    }
    return url;
  }

  /// Checks if a given text string is a valid URL
  static bool isValidUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final match = urlRegex.firstMatch(trimmed);
    return match != null && match.group(0) == trimmed;
  }

  /// Extracts domain host for nice user presentation
  static String extractDomain(String url) {
    try {
      final normalized = normalizeUrl(url);
      final uri = Uri.parse(normalized);
      final host = uri.host.isNotEmpty ? uri.host : url;
      return host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url;
    }
  }

  /// Automatically scans document plain text and applies LinkAttribute to URL ranges
  static void autoFormatLinks(Document doc) {
    final plainText = doc.toPlainText();
    final matches = urlRegex.allMatches(plainText);

    for (final match in matches) {
      var rawMatch = match.group(0)!;
      var start = match.start;
      var end = match.end;

      while (rawMatch.isNotEmpty &&
          (rawMatch.endsWith('.') ||
              rawMatch.endsWith(',') ||
              rawMatch.endsWith(';') ||
              rawMatch.endsWith('!') ||
              rawMatch.endsWith('?') ||
              rawMatch.endsWith(')'))) {
        if (rawMatch.endsWith(')') && rawMatch.contains('(')) break;
        rawMatch = rawMatch.substring(0, rawMatch.length - 1);
        end--;
      }

      if (rawMatch.isEmpty) continue;
      final len = end - start;
      if (len <= 0) continue;

      final normalizedUrl = normalizeUrl(rawMatch);
      final currentStyle = doc.collectStyle(start, len);
      final existingLink = currentStyle.attributes[Attribute.link.key]?.value;

      if (existingLink != normalizedUrl) {
        doc.format(start, len, LinkAttribute(normalizedUrl));
      }
    }
  }

  /// Launches a URL in external browser
  static Future<bool> launchInBrowser(BuildContext context, String rawUrl) async {
    final normalized = normalizeUrl(rawUrl);
    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format tautan tidak valid'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        // Fallback with platformDefault if externalApplication is unsupported
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka browser untuk tautan ini'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka tautan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  /// Shows the dialog/bottom sheet prompting the user to open the link in browser
  static Future<void> showLinkActionDialog(
    BuildContext context,
    String rawUrl, {
    QuillController? controller,
  }) async {
    final normalizedUrl = normalizeUrl(rawUrl);
    final domain = extractDomain(rawUrl);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag indicator
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header with icon and domain
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFC7D2FE),
                        ),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buka Tautan?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Link Preview Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          normalizedUrl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action 1: Buka di Browser (Primary CTA)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await launchInBrowser(context, normalizedUrl);
                    },
                    icon: const Icon(
                      Icons.open_in_browser_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Buka di Browser',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Row of secondary actions: Salin Tautan & Batal / Hapus
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: normalizedUrl));
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tautan berhasil disalin'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Color(0xFF475569),
                          ),
                          label: const Text(
                            'Salin Tautan',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog to insert or edit a link on current controller selection
  static Future<void> showEditLinkDialog(
    BuildContext context,
    QuillController controller,
  ) async {
    final selection = controller.selection;
    final style = controller.getSelectionStyle();
    final existingLink = style.attributes[Attribute.link.key]?.value?.toString() ?? '';

    final urlController = TextEditingController(text: existingLink);
    final isEditing = existingLink.isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Ubah Tautan' : 'Sisipkan Tautan',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan alamat URL / link:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'https://example.com atau www.google.com',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () {
                  controller.formatSelection(Attribute.clone(Attribute.link, null));
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Hapus Tautan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final input = urlController.text.trim();
                if (input.isNotEmpty) {
                  final normalized = normalizeUrl(input);
                  if (selection.isCollapsed) {
                    // Insert link text at cursor
                    controller.document.insert(selection.start, normalized);
                    controller.document.format(
                      selection.start,
                      normalized.length,
                      LinkAttribute(normalized),
                    );
                    controller.updateSelection(
                      TextSelection.collapsed(
                        offset: selection.start + normalized.length,
                      ),
                      ChangeSource.local,
                    );
                  } else {
                    controller.formatSelection(LinkAttribute(normalized));
                  }
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

