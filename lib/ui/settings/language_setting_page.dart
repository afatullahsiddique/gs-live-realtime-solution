import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LanguageSettingPage extends StatefulWidget {
  const LanguageSettingPage({super.key});

  @override
  State<LanguageSettingPage> createState() => _LanguageSettingPageState();
}

class _LanguageSettingPageState extends State<LanguageSettingPage> {
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'Follow system',
    'English',
    '繁體中文',
    'Tiếng Việt',
    'हिंदी',
    'Bahasa Indonesia',
    'العربية',
    'اردو',
    'Português',
    'Türkçe',
    'বাংলা',
    'ภาษาไทย',
    'नेपाली',
    'Français',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Language Setting',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Color(0xFF908DFF),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      body: ListView.separated(
        itemCount: _languages.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, color: Color(0xFFF5F5F9)),
        itemBuilder: (context, index) {
          final language = _languages[index];
          final isSelected = _selectedLanguage == language;
          return ListTile(
            onTap: () => setState(() => _selectedLanguage = language),
            title: Text(
              language,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? const Color(0xFF5E5CFF) : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5E5CFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  )
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12, width: 1.5),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
