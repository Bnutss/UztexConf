import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/locale_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  String _lang = 'ru';
  bool _permissionsRequested = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _gradientColors = [Color(0xFFFF8C00), Color(0xFFCC1500)];

  // ── Translations ──────────────────────────────────────────────────────────
  static const _t = {
    'ru': {
      'select_lang': 'Выберите язык',
      'select_lang_sub': 'Вы сможете изменить язык в настройках',
      'welcome': 'Добро пожаловать!',
      'welcome_sub':
          'UztexConf — профессиональная платформа для видеоконференций внутри вашей компании',
      'feat1_chip1': 'Видеоконференции',
      'feat1_chip2': 'Многопользовательские звонки',
      'feat1_chip3': 'Безопасная связь',
      'rooms_title': 'Видеокомнаты',
      'rooms_sub':
          'Создавайте конференц-комнаты и приглашайте коллег. Войти в звонок можно одним нажатием — без ссылок и паролей',
      'live_title': 'Живое общение',
      'live_sub':
          'Высококачественное видео и аудио в реальном времени. Переключайте камеру, выключайте микрофон, общайтесь без задержек',
      'perm_title': 'Разрешения',
      'perm_sub':
          'Для видео- и аудиозвонков необходим доступ к камере и микрофону. Данные остаются только на вашем устройстве',
      'perm_btn': 'Разрешить доступ',
      'perm_skip': 'Разрешить позже',
      'next': 'Далее',
      'start': 'Начать',
    },
    'en': {
      'select_lang': 'Select Language',
      'select_lang_sub': 'You can change the language in settings',
      'welcome': 'Welcome!',
      'welcome_sub':
          'UztexConf — a professional video conferencing platform for your company',
      'feat1_chip1': 'Video Conferencing',
      'feat1_chip2': 'Multi-user Calls',
      'feat1_chip3': 'Secure Communication',
      'rooms_title': 'Video Rooms',
      'rooms_sub':
          'Create conference rooms and invite colleagues. Join a call with one tap — no links or passwords needed',
      'live_title': 'Live Communication',
      'live_sub':
          'High-quality video and audio in real time. Switch camera, mute microphone, communicate without delay',
      'perm_title': 'Permissions',
      'perm_sub':
          'Camera and microphone access are required for video and audio calls. Data stays on your device only',
      'perm_btn': 'Allow Access',
      'perm_skip': 'Allow Later',
      'next': 'Next',
      'start': 'Get Started',
    },
    'uz': {
      'select_lang': 'Tilni tanlang',
      'select_lang_sub': "Tilni sozlamalarda o'zgartirish mumkin",
      'welcome': 'Xush kelibsiz!',
      'welcome_sub':
          "UztexConf — kompaniyangiz ichida professional video konferensiya platformasi",
      'feat1_chip1': 'Video konferensiya',
      'feat1_chip2': "Ko'p foydalanuvchili qo'ng'iroqlar",
      'feat1_chip3': 'Xavfsiz aloqa',
      'rooms_title': 'Video xonalar',
      'rooms_sub':
          "Konferens xonalar yarating va hamkasblarni taklif qiling. Bir tugmada qo'ng'iroqqa kirish mumkin",
      'live_title': 'Jonli muloqot',
      'live_sub':
          "Real vaqtda yuqori sifatli video va audio. Kamerani almashtiring, mikrofonni o'chiring",
      'perm_title': 'Ruxsatlar',
      'perm_sub':
          "Video va audio qo'ng'iroqlar uchun kamera va mikrofonga ruxsat kerak. Ma'lumotlar faqat qurilmangizda qoladi",
      'perm_btn': 'Ruxsat berish',
      'perm_skip': "Keyinroq ruxsat berish",
      'next': 'Keyingi',
      'start': 'Boshlash',
    },
  };

  String _tr(String key) => _t[_lang]?[key] ?? _t['ru']![key] ?? key;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int i) => setState(() => _currentPage = i);

  void _selectLang(String lang) {
    setState(() => _lang = lang);
  }

  Future<void> _requestPermissions() async {
    setState(() => _permissionsRequested = true);
    await [Permission.camera, Permission.microphone].request();
    await _finish();
  }

  Future<void> _finish() async {
    await LocaleService.instance.setLanguage(_lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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
        body: Stack(
          children: [
            _buildBackground(),
            _buildDecoCircles(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildLangPage(),
                        _buildWelcomePage(),
                        _buildFeaturePage(
                          icon: Icons.video_camera_front_rounded,
                          iconColor: const Color(0xFFFF8C00),
                          glowColor: const Color(0xFFCC1500),
                          titleKey: 'rooms_title',
                          subKey: 'rooms_sub',
                          bullets: [
                            (Icons.add_circle_outline_rounded, _bulletRooms(0)),
                            (Icons.person_add_alt_rounded, _bulletRooms(1)),
                            (Icons.touch_app_rounded, _bulletRooms(2)),
                          ],
                        ),
                        _buildFeaturePage(
                          icon: Icons.mic_rounded,
                          iconColor: const Color(0xFF34D399),
                          glowColor: const Color(0xFF059669),
                          titleKey: 'live_title',
                          subKey: 'live_sub',
                          bullets: [
                            (Icons.hd_rounded, _bulletLive(0)),
                            (Icons.flip_camera_ios_rounded, _bulletLive(1)),
                            (Icons.volume_up_rounded, _bulletLive(2)),
                          ],
                        ),
                        _buildPermPage(),
                      ],
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers for bullet points ─────────────────────────────────────────────
  String _bulletRooms(int i) {
    const ru = [
      'Создавайте комнаты',
      'Приглашайте коллег',
      'Входите одним нажатием',
    ];
    const en = ['Create rooms', 'Invite colleagues', 'Join with one tap'];
    const uz = [
      "Xonalar yarating",
      "Hamkasblarni taklif qiling",
      "Bir tugmada kiring",
    ];
    final map = {'ru': ru, 'en': en, 'uz': uz};
    return map[_lang]?[i] ?? ru[i];
  }

  String _bulletLive(int i) {
    const ru = ['HD видео и аудио', 'Переключение камеры', 'Управление звуком'];
    const en = ['HD video and audio', 'Camera switching', 'Sound control'];
    const uz = [
      "HD video va audio",
      "Kamerani almashtirish",
      "Ovozni boshqarish",
    ];
    final map = {'ru': ru, 'en': en, 'uz': uz};
    return map[_lang]?[i] ?? ru[i];
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildDecoCircles() {
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -60,
          child: _decoCircle(240, Colors.white, 0.06),
        ),
        Positioned(
          top: 130,
          right: 25,
          child: _decoCircle(70, Colors.white, 0.04),
        ),
        Positioned(
          bottom: 80,
          left: -90,
          child: _decoCircle(260, Colors.white, 0.05),
        ),
        Positioned(
          bottom: 220,
          right: -35,
          child: _decoCircle(110, Colors.white, 0.04),
        ),
        Positioned(
          top: 300,
          left: 20,
          child: _decoCircle(50, Colors.white, 0.06),
        ),
      ],
    );
  }

  Widget _decoCircle(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(opacity),
    ),
  );

  // ── Page 0: Language selection ────────────────────────────────────────────
  Widget _buildLangPage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              _buildLogo(size: 100),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              Text(
                _tr('select_lang'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _tr('select_lang_sub'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),
              _langButton('ru', '🇷🇺', 'Русский', 'Russian'),
              const SizedBox(height: 14),
              _langButton('en', '🇬🇧', 'English', 'English'),
              const SizedBox(height: 14),
              _langButton('uz', '🇺🇿', "O'zbek", 'Uzbek'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langButton(String lang, String flag, String native, String sub) {
    final selected = _lang == lang;
    return GestureDetector(
      onTap: () => _selectLang(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.22)
              : Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.2),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.08),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    native,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome ───────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    final chips = [
      (Icons.meeting_room_rounded, _tr('feat1_chip1')),
      (Icons.group_rounded, _tr('feat1_chip2')),
      (Icons.security_rounded, _tr('feat1_chip3')),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogo(size: 110, glow: true),
          const SizedBox(height: 28),
          Text(
            _tr('welcome'),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            _tr('welcome_sub'),
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.78),
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          ...chips.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _glassChip(c.$1, c.$2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double size = 90, bool glow = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _glassChip(IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.11),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFF8C00), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pages 2 & 3: Feature pages ────────────────────────────────────────────
  Widget _buildFeaturePage({
    required IconData icon,
    required Color iconColor,
    required Color glowColor,
    required String titleKey,
    required String subKey,
    required List<(IconData, String)> bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.35),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 68),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _tr(titleKey),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _tr(subKey),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.75),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _bulletRow(b.$1, b.$2, iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Page 4: Permissions ───────────────────────────────────────────────────
  Widget _buildPermPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dual icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _permIcon(
                Icons.videocam_rounded,
                const Color(0xFFFF8C00),
                const Color(0xFFCC1500),
              ),
              const SizedBox(width: 20),
              _permIcon(
                Icons.mic_rounded,
                const Color(0xFF34D399),
                const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            _tr('perm_title'),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            _tr('perm_sub'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.78),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _glassActionButton(
            label: _tr('perm_btn'),
            icon: Icons.check_circle_outline_rounded,
            onTap: _permissionsRequested ? null : _requestPermissions,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _permissionsRequested ? null : _finish,
            child: Text(
              _tr('perm_skip'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permIcon(IconData icon, Color color, Color glow) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 48),
        ),
      ),
    );
  }

  Widget _glassActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.white.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.04),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
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

  // ── Bottom bar with dots + Next button ────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentPage == 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Row(
        children: [
          // Dots
          Expanded(
            child: Row(
              children: List.generate(5, (i) {
                final active = _currentPage == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(right: 7),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          if (!isLast)
            GestureDetector(
              onTap: _nextPage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tr('next'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
