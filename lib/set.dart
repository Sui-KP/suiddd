import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/main.dart';

class SettingsScreen extends StatefulWidget {
  final LanguageNotifier languageNotifier;
  final ThemeColorNotifier themeColorNotifier;
  const SettingsScreen({super.key, required this.languageNotifier, required this.themeColorNotifier});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Locale _currentLocale;
  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadSavedColor();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLocale = Localizations.localeOf(context);
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('languageCode');
    final country = prefs.getString('countryCode');
    if (code != null && country != null) {
      setState(() => _currentLocale = Locale(code, country));
    }
  }

  Future<void> _loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('primaryColor');
    if (colorValue != null) {}
  }

  Future<void> _changeLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    await prefs.setString('countryCode', locale.countryCode ?? '');
    widget.languageNotifier.setLocale(locale);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SplashScreen(languageNotifier: widget.languageNotifier, themeColorNotifier: widget.themeColorNotifier),
      ),
      (route) => false,
    );
  }

  Future<void> _changeThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.toARGB32());
    widget.themeColorNotifier.setPrimaryColor(color);
    if (mounted) {}
  }

  Widget _buildLanguageOption(String title, Locale locale) {
    final bool isSelected = _currentLocale.languageCode == locale.languageCode;
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Symbols.check_rounded) : null,
      onTap: () {
        _changeLanguage(locale);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        _changeThemeColor(color);
        Navigator.of(context).pop();
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context)!;
    final isChinese = _currentLocale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l.language),
            subtitle: Text(isChinese ? '中文 (简体)' : 'English (US)'),
            trailing: const Icon(Symbols.arrow_forward_ios_rounded),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l.select_language),
                content: Column(mainAxisSize: MainAxisSize.min, children: [_buildLanguageOption('中文 (简体)', const Locale('zh', 'CN')), _buildLanguageOption('English (US)', const Locale('en', 'US'))]),
              ),
            ),
          ),
          ListTile(
            title: Text(l.theme_color),
            trailing: const Icon(Symbols.arrow_forward_ios_rounded),
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l.select_theme_color),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildColorOption(Colors.teal), _buildColorOption(Colors.blue), _buildColorOption(Colors.green)]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildColorOption(Colors.orange), _buildColorOption(Colors.purple), _buildColorOption(Colors.red)]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
