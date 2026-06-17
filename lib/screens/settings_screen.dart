import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';
import '../services/locale_service.dart';
import '../screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  static const _gradStart = Color(0xFFFF8C00);
  static const _gradEnd = Color(0xFFCC1500);

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  String _fullName = '';
  String _username = '';
  String _appVersion = '';
  String _buildNumber = '';

  final _languages = const [
    {'code': 'ru', 'name': 'Русский', 'desc': 'Russian', 'flag': '🇷🇺'},
    {'code': 'en', 'name': 'English', 'desc': 'English', 'flag': '🇬🇧'},
    {'code': 'uz', 'name': "O'zbek", 'desc': 'Uzbek', 'flag': '🇺🇿'},
  ];

  String _s(String key) => LocaleService.instance.tr(key);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
    _loadUser();
    LocaleService.instance.addListener(_onLocale);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    LocaleService.instance.removeListener(_onLocale);
    super.dispose();
  }

  void _onLocale() => setState(() {});

  Future<void> _loadUser() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    }
    final fn = await ApiService.getFullName();
    final un = await ApiService.getUsername();
    if (mounted) {
      setState(() {
        _fullName = fn ?? '';
        _username = un ?? '';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _GlassAppBar(
          title: _s('settings'),
          onBack: () => Navigator.of(context).pop(),
          onInfo: _showAboutDialog,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradStart, _gradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -60, right: -40, child: _circle(200, 0.06)),
              Positioned(bottom: 60, left: -70, child: _circle(220, 0.05)),
              Positioned(top: 240, right: 20, child: _circle(60, 0.04)),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 28),
                      _buildSectionHeader(_s('general')),
                      const SizedBox(height: 10),
                      _buildSettingTile(
                        icon: Icons.language_rounded,
                        title: _s('language'),
                        subtitle: _s('language_desc'),
                        onTap: _showLanguageDialog,
                      ),
                      const SizedBox(height: 28),
                      _buildSectionHeader(_s('profile')),
                      const SizedBox(height: 10),
                      _buildLogoutTile(),
                      const SizedBox(height: 36),
                      _buildVersionBadge(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
              shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    final display = _fullName.isNotEmpty ? _fullName : _username;
    final initials = display.isNotEmpty
        ? display.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: _gradStart,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              display.isNotEmpty ? display : 'UztexConf',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.3,
                shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
              ),
            ),
            if (_username.isNotEmpty && _username != _fullName) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alternate_email_rounded, color: Colors.white.withOpacity(0.6), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    _username,
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_rounded, color: Colors.white.withOpacity(0.75), size: 13),
                  const SizedBox(width: 7),
                  Text(
                    _s('conference_system'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Setting Tile ──────────────────────────────────────────────────────────

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.7), size: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout Tile ───────────────────────────────────────────────────────────

  Widget _buildLogoutTile() {
    return _GlassCard(
      onTap: _confirmLogout,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _s('logout'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.7), size: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Version Badge ─────────────────────────────────────────────────────────

  Widget _buildVersionBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 7),
            Text(
              'UztexConf v${_appVersion.isNotEmpty ? _appVersion : '...'}${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ── Language Dialog ───────────────────────────────────────────────────────

  void _showLanguageDialog() {
    String selected = LocaleService.instance.lang;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.language_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _s('select_language'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Language options
                    ..._languages.map((lang) {
                      final isSelected = selected == lang['code'];
                      return GestureDetector(
                        onTap: () => setDlg(() => selected = lang['code']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: isSelected ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.18),
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(shape: BoxShape.circle, color: _gradStart),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 13),
                              Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang['name']!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      lang['desc']!,
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.8),
                              ),
                              child: Center(
                                child: Text(
                                  _s('cancel'),
                                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await LocaleService.instance.setLanguage(selected);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_gradStart, _gradEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: _gradStart.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                              ),
                              child: Center(
                                child: Text(
                                  _s('save'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout Confirm ────────────────────────────────────────────────────────

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(_s('logout_confirm_title'),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(_s('logout_confirm_body'),
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.8),
                            ),
                            child: Center(
                              child: Text(_s('cancel'),
                                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_gradStart, _gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: _gradStart.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Center(
                              child: Text(_s('logout_confirm'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
      ),
    );

    if (confirm != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── About Dialog ──────────────────────────────────────────────────────────

  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'UztexConf',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${_s('version')} ${_appVersion.isNotEmpty ? _appVersion : '...'}${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '© 2026 UztexConf.',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _s('copyright'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gradStart, _gradEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: _gradStart.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _s('close'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Glass Card ───────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _GlassCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.22), width: 0.8),
            ),
            child: onTap != null
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(18),
                      splashColor: Colors.white.withOpacity(0.08),
                      highlightColor: Colors.white.withOpacity(0.05),
                      child: child,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

// ── Glass AppBar ──────────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onInfo;

  const _GlassAppBar({required this.title, required this.onBack, required this.onInfo});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: ColoredBox(
          color: Colors.white.withOpacity(0.08),
          child: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: onBack,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
                onPressed: onInfo,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ),
    );
  }
}
