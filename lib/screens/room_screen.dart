import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uztexconf/services/locale_service.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String livekitUrl;
  final String token;
  final String username;

  const RoomScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.livekitUrl,
    required this.token,
    required this.username,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  late final Room _room;
  late final EventsListener<RoomEvent> _listener;

  bool _connected = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _speakerEnabled = true;
  bool _connecting = true;
  bool _isFrontCamera = true;
  bool _hasLeft = false;
  String? _error;

  final List<ParticipantTrack> _participantTracks = [];

  int? _focusedIndex;
  late final AnimationController _focusAnimController;
  late final Animation<double> _focusAnim;
  PageController? _focusedPageController;

  @override
  void initState() {
    super.initState();

    _focusAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusAnim = CurvedAnimation(
      parent: _focusAnimController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultVideoPublishOptions: VideoPublishOptions(simulcast: false),
      ),
    );
    _listener = _room.createListener();
    _setupListeners();
    _connect();
  }

  void _setupListeners() {
    _listener
      ..on<RoomConnectedEvent>((event) async {
        setState(() {
          _connected = true;
          _connecting = false;
        });
        // Delay track publishing on desktop to let WebRTC fully initialize
        if (_isDesktop) await Future.delayed(const Duration(milliseconds: 500));
        await _publishLocalTracks();
        _rebuildTracks();
      })
      ..on<RoomDisconnectedEvent>((event) => _leaveRoom())
      ..on<ParticipantConnectedEvent>((event) => _rebuildTracks())
      ..on<ParticipantDisconnectedEvent>((event) => _rebuildTracks())
      ..on<LocalTrackPublishedEvent>((event) => _rebuildTracks())
      ..on<LocalTrackUnpublishedEvent>((event) => _rebuildTracks())
      ..on<TrackSubscribedEvent>((event) => _rebuildTracks())
      ..on<TrackUnsubscribedEvent>((event) => _rebuildTracks())
      ..on<TrackMutedEvent>((event) => _rebuildTracks())
      ..on<TrackUnmutedEvent>((event) => _rebuildTracks())
      ..on<ActiveSpeakersChangedEvent>((event) => _rebuildTracks());
  }

  Future<void> _publishLocalTracks() async {
    // Microphone first — more reliable
    try {
      await _room.localParticipant?.setMicrophoneEnabled(true);
    } catch (_) {
      if (mounted) setState(() => _micEnabled = false);
    }

    // Camera — check availability on desktop before enabling
    try {
      if (_isDesktop) {
        final devices = await webrtc.navigator.mediaDevices.enumerateDevices();
        final hasCamera = devices.any((d) => d.kind == 'videoinput');
        if (!hasCamera) {
          if (mounted) setState(() => _cameraEnabled = false);
          return;
        }
      }
      await _room.localParticipant?.setCameraEnabled(true);
    } catch (_) {
      if (mounted) setState(() => _cameraEnabled = false);
    }
  }

  void _rebuildTracks() {
    if (!mounted) return;
    final tracks = <ParticipantTrack>[];

    final local = _room.localParticipant;
    if (local != null) {
      final videoTrack = local.videoTrackPublications
          .where((p) => !p.muted && p.track != null)
          .map((p) => p.track as VideoTrack)
          .firstOrNull;
      tracks.add(
        ParticipantTrack(
          participant: local,
          videoTrack: videoTrack,
          isLocal: true,
          mirror: _isFrontCamera,
        ),
      );
    }

    for (final participant in _room.remoteParticipants.values) {
      final videoTrack = participant.videoTrackPublications
          .where((p) => p.subscribed && !p.muted && p.track != null)
          .map((p) => p.track as VideoTrack)
          .firstOrNull;
      tracks.add(
        ParticipantTrack(
          participant: participant,
          videoTrack: videoTrack,
          isLocal: false,
        ),
      );
    }

    setState(() {
      _participantTracks
        ..clear()
        ..addAll(tracks);
      if (_focusedIndex != null && _focusedIndex! >= tracks.length) {
        _focusedIndex = tracks.isEmpty ? null : tracks.length - 1;
      }
    });
  }

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _connect() async {
    try {
      if (!_isDesktop) {
        final cameraStatus = await Permission.camera.request();
        final micStatus = await Permission.microphone.request();

        if (!mounted) return;

        if (cameraStatus.isDenied || micStatus.isDenied) {
          setState(() {
            _error = LocaleService.instance.tr('permissions_error');
            _connecting = false;
          });
          return;
        }
      }

      await _room.connect(widget.livekitUrl, widget.token);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${LocaleService.instance.tr('connection_error')}${e.toString()}';
          _connecting = false;
        });
      }
    }
  }

  Future<void> _toggleMic() async {
    await _room.localParticipant?.setMicrophoneEnabled(!_micEnabled);
    setState(() => _micEnabled = !_micEnabled);
  }

  Future<void> _toggleCamera() async {
    await _room.localParticipant?.setCameraEnabled(!_cameraEnabled);
    setState(() => _cameraEnabled = !_cameraEnabled);
  }

  Future<void> _switchCamera() async {
    final pub = _room.localParticipant?.videoTrackPublications
        .where((p) => p.track is LocalVideoTrack)
        .firstOrNull;
    final track = pub?.track as LocalVideoTrack?;
    if (track == null) return;
    try {
      await webrtc.Helper.switchCamera(track.mediaStreamTrack);
      if (mounted) {
        setState(() => _isFrontCamera = !_isFrontCamera);
        _rebuildTracks();
      }
    } catch (_) {}
  }

  void _toggleSpeaker() {
    setState(() => _speakerEnabled = !_speakerEnabled);
    Hardware.instance.setSpeakerphoneOn(_speakerEnabled);
  }

  void _leaveRoom() {
    if (_hasLeft) return;
    _hasLeft = true;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _disconnect() async {
    await _room.disconnect();
    _leaveRoom();
  }

  void _expandParticipant(int index) {
    _focusedPageController?.dispose();
    _focusedPageController = PageController(initialPage: index);
    setState(() => _focusedIndex = index);
    _focusAnimController.forward();
  }

  void _closeFocusedView() {
    _focusAnimController.reverse().then((_) {
      if (mounted) {
        setState(() => _focusedIndex = null);
        _focusedPageController?.dispose();
        _focusedPageController = null;
      }
    });
  }

  @override
  void dispose() {
    _focusAnimController.dispose();
    _focusedPageController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _listener.dispose();
    _room.dispose();
    super.dispose();
  }

  int _getColumns(int count) {
    if (count <= 2) return 1;
    if (count <= 6) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 52, bottom: 100),
              child: _buildParticipantsGrid(),
            ),
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
            Positioned(bottom: 0, left: 0, right: 0, child: _buildControls()),
            if (_focusedIndex != null)
              Positioned.fill(child: _buildFocusedOverlay()),
            if (_connecting || _error != null)
              Positioned.fill(child: _buildStatusOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsGrid() {
    if (_participantTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF161823),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF334155),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleService.instance.tr('waiting_participants'),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final count = _participantTracks.length;
    final cols = _getColumns(count);
    final rows = (count / cols).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: List.generate(rows, (row) {
          final start = row * cols;
          final end = (start + cols).clamp(0, count);
          final items = _participantTracks.sublist(start, end);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final idx = start + entry.key;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _ParticipantTile(
                        track: entry.value,
                        onTap: () => _expandParticipant(idx),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0F), Color(0x000A0A0F)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.videocam_rounded,
              color: Color(0xFF3B82F6),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.roomName,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_participantTracks.length}',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF0A0A0F), Color(0x000A0A0F)],
          stops: [0.4, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: LocaleService.instance.tr('mic'),
            onTap: _toggleMic,
            isActive: _micEnabled,
          ),
          _ControlButton(
            icon: _cameraEnabled
                ? Icons.videocam_rounded
                : Icons.videocam_off_rounded,
            label: LocaleService.instance.tr('camera'),
            onTap: _toggleCamera,
            isActive: _cameraEnabled,
          ),
          _ControlButton(
            icon: Icons.cameraswitch_rounded,
            label: LocaleService.instance.tr('switch_camera'),
            onTap: _switchCamera,
            isActive: true,
          ),
          _ControlButton(
            icon: _speakerEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            label: LocaleService.instance.tr('speaker'),
            onTap: _toggleSpeaker,
            isActive: _speakerEnabled,
          ),
          _ControlButton(
            icon: Icons.call_end_rounded,
            label: LocaleService.instance.tr('leave'),
            onTap: _disconnect,
            isActive: false,
            isEndCall: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusedOverlay() {
    final track = _participantTracks[_focusedIndex!];

    return FadeTransition(
      opacity: _focusAnim,
      child: ScaleTransition(
        scale: Tween(begin: 0.93, end: 1.0).animate(_focusAnim),
        child: Material(
          color: const Color(0xFF0A0A0F),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _focusedPageController,
                onPageChanged: (i) => setState(() => _focusedIndex = i),
                itemCount: _participantTracks.length,
                itemBuilder: (context, index) {
                  return _FocusedParticipantView(
                    track: _participantTracks[index],
                  );
                },
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0A0A0F).withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _closeFocusedView,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          track.isLocal
                              ? LocaleService.instance.tr('you_label').replaceAll('{identity}', track.participant.identity)
                              : track.participant.identity,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _MicCamIndicator(
                        participant: track.participant,
                        large: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (_participantTracks.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _PageDots(
                      count: _participantTracks.length,
                      current: _focusedIndex!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Container(
      color: const Color(0xFF0A0A0F).withValues(alpha: 0.9),
      child: Center(
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        LocaleService.instance.tr('leave'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF3B82F6),
                      strokeWidth: 3,
                      backgroundColor: const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    LocaleService.instance.tr('connecting'),
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Data ──────────────────────────────────────────────────────────────

class ParticipantTrack {
  final Participant participant;
  final VideoTrack? videoTrack;
  final bool isLocal;
  final bool mirror;

  ParticipantTrack({
    required this.participant,
    required this.videoTrack,
    required this.isLocal,
    this.mirror = false,
  });
}

// ─── Participant Tile (Grid) ──────────────────────────────────────────

class _ParticipantTile extends StatelessWidget {
  final ParticipantTrack track;
  final VoidCallback onTap;

  const _ParticipantTile({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final video = track.videoTrack;
    final name = track.participant.identity;
    final isSpeaking = track.participant.isSpeaking;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF161823),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSpeaking
                ? const Color(0xFF22C55E).withValues(alpha: 0.6)
                : const Color(0xFF1E2030),
            width: isSpeaking ? 2.0 : 1.0,
          ),
          boxShadow: isSpeaking
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Transform.scale(
                  scaleX: track.mirror ? 1.0 : -1.0,
                  child: VideoTrackRenderer(video),
                ),
              )
            else
              _AvatarPlaceholder(name: name),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    if (track.isLocal)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          LocaleService.instance.tr('you'),
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _MicCamIndicator(participant: track.participant),
                  ],
                ),
              ),
            ),

            if (isSpeaking)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFF22C55E),
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Focused Participant View (Expanded) ──────────────────────────────

class _FocusedParticipantView extends StatelessWidget {
  final ParticipantTrack track;

  const _FocusedParticipantView({required this.track});

  @override
  Widget build(BuildContext context) {
    final video = track.videoTrack;
    final name = track.participant.identity;

    if (video != null) {
      return Transform.scale(
        scaleX: track.mirror ? 1.0 : -1.0,
        child: VideoTrackRenderer(video),
      );
    }

    return _AvatarPlaceholder(name: name, fullscreen: true);
  }
}

// ─── Avatar Placeholder ───────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  final bool fullscreen;

  const _AvatarPlaceholder({required this.name, this.fullscreen = false});

  static const _gradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[name.hashCode.abs() % _gradients.length];
    final radius = fullscreen ? 48.0 : 32.0;
    final fontSize = fullscreen ? 36.0 : 24.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (fullscreen) ...[
            const SizedBox(height: 14),
            Text(
              name,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Mic/Camera Status Indicator ──────────────────────────────────────

class _MicCamIndicator extends StatelessWidget {
  final Participant participant;
  final bool large;

  const _MicCamIndicator({required this.participant, this.large = false});

  @override
  Widget build(BuildContext context) {
    final isMicOff =
        participant.audioTrackPublications.isEmpty ||
        participant.audioTrackPublications.every((p) => p.muted);
    final isCamOff =
        participant.videoTrackPublications.isEmpty ||
        participant.videoTrackPublications.every(
          (p) => p.muted || p.track == null,
        );

    if (!isMicOff && !isCamOff) return const SizedBox.shrink();

    final iconSize = large ? 16.0 : 12.0;
    final pad = large
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 5, vertical: 3);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMicOff)
            Icon(
              Icons.mic_off_rounded,
              color: const Color(0xFFEF4444),
              size: iconSize,
            ),
          if (isMicOff && isCamOff) SizedBox(width: large ? 6 : 4),
          if (isCamOff)
            Icon(
              Icons.videocam_off_rounded,
              color: const Color(0xFFEF4444),
              size: iconSize,
            ),
        ],
      ),
    );
  }
}

// ─── Control Button ───────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isEndCall;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
    this.isEndCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEndCall
                  ? const Color(0xFFEF4444)
                  : isActive
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF1E293B).withValues(alpha: 0.5),
              border: isEndCall
                  ? null
                  : Border.all(
                      color: isActive
                          ? const Color(0xFF334155)
                          : const Color(0xFF1E293B),
                    ),
              boxShadow: isEndCall
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isEndCall
                  ? Colors.white
                  : isActive
                  ? Colors.white
                  : const Color(0xFF64748B),
              size: 23,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isEndCall
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page Dots Indicator ──────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF334155),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
