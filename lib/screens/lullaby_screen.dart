import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 자장가 / 백색소음 플레이어 화면
class LullabyScreen extends StatefulWidget {
  const LullabyScreen({super.key});

  @override
  State<LullabyScreen> createState() => _LullabyScreenState();
}

class _LullabyScreenState extends State<LullabyScreen>
    with TickerProviderStateMixin {
  _SoundItem? _currentSound;
  bool _isPlaying = false;
  double _volume = 0.7;
  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;
  int _sleepTimerRemaining = 0;
  late AnimationController _pulseController;

  static final List<_SoundItem> _sounds = [
    _SoundItem(id: 'rain', name: '빗소리', emoji: '🌧️', color: Color(0xFF90CAF9)),
    _SoundItem(id: 'ocean', name: '파도 소리', emoji: '🌊', color: Color(0xFF80DEEA)),
    _SoundItem(id: 'heartbeat', name: '심장박동', emoji: '💓', color: Color(0xFFEF9A9A)),
    _SoundItem(id: 'whitenoise', name: '백색소음', emoji: '☁️', color: Color(0xFFE0E0E0)),
    _SoundItem(id: 'fan', name: '선풍기', emoji: '🌀', color: Color(0xFFA5D6A7)),
    _SoundItem(id: 'vacuum', name: '청소기', emoji: '🧹', color: Color(0xFFCE93D8)),
    _SoundItem(id: 'lullaby1', name: '자장가 1', emoji: '🎵', color: Color(0xFFFFE082)),
    _SoundItem(id: 'lullaby2', name: '자장가 2', emoji: '🎶', color: Color(0xFFFFCC80)),
    _SoundItem(id: 'birdsong', name: '새소리', emoji: '🐦', color: Color(0xFFC5E1A5)),
    _SoundItem(id: 'creek', name: '시냇물', emoji: '💧', color: Color(0xFF81D4FA)),
    _SoundItem(id: 'fireplace', name: '벽난로', emoji: '🔥', color: Color(0xFFFFAB91)),
    _SoundItem(id: 'shushing', name: '쉬~ 소리', emoji: '🤫', color: Color(0xFFB39DDB)),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleSound(_SoundItem sound) {
    setState(() {
      if (_currentSound?.id == sound.id && _isPlaying) {
        _isPlaying = false;
        _currentSound = null;
      } else {
        _currentSound = sound;
        _isPlaying = true;
      }
    });
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('수면 타이머', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                const SizedBox(height: 4),
                Text('설정한 시간 후 소리가 자동으로 꺼져요',
                  style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [0, 15, 30, 45, 60, 90].map((min) {
                    final label = min == 0 ? '끄기' : '$min분';
                    final isActive = _sleepTimerMinutes == min;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isActive,
                      selectedColor: AppTheme.primaryContainer,
                      onSelected: (_) {
                        Navigator.pop(ctx);
                        _setSleepTimer(min);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
      _sleepTimerRemaining = minutes * 60;
    });
    if (minutes > 0) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _sleepTimerRemaining--;
          if (_sleepTimerRemaining <= 0) {
            _isPlaying = false;
            _currentSound = null;
            _sleepTimerMinutes = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('자장가 & 백색소음'),
        backgroundColor: AppTheme.background,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _sleepTimerMinutes > 0,
              label: Text('${_sleepTimerRemaining ~/ 60}'),
              child: const Icon(Icons.timer_outlined),
            ),
            onPressed: _showSleepTimerSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Now Playing area
          if (_isPlaying && _currentSound != null) ...[
            const SizedBox(height: 16),
            _NowPlayingCard(
              sound: _currentSound!,
              isPlaying: _isPlaying,
              volume: _volume,
              pulseController: _pulseController,
              sleepTimerRemaining: _sleepTimerRemaining,
              onVolumeChanged: (v) => setState(() => _volume = v),
              onStop: () => setState(() {
                _isPlaying = false;
                _currentSound = null;
              }),
            ),
          ],

          const SizedBox(height: 20),

          // Sound Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              itemCount: _sounds.length,
              itemBuilder: (ctx, idx) {
                final sound = _sounds[idx];
                final isActive =
                    _currentSound?.id == sound.id && _isPlaying;
                return _SoundTile(
                  sound: sound,
                  isActive: isActive,
                  onTap: () => _toggleSound(sound),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundItem {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  const _SoundItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}

class _SoundTile extends StatelessWidget {
  final _SoundItem sound;
  final bool isActive;
  final VoidCallback onTap;

  const _SoundTile({
    required this.sound,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isActive
              ? sound.color.withOpacity(0.3)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: sound.color, width: 2)
              : null,
          boxShadow: isActive
              ? [BoxShadow(color: sound.color.withOpacity(0.2), blurRadius: 12)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(sound.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              sound.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.pause_circle_filled,
                    size: 16, color: sound.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final _SoundItem sound;
  final bool isPlaying;
  final double volume;
  final AnimationController pulseController;
  final int sleepTimerRemaining;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onStop;

  const _NowPlayingCard({
    required this.sound,
    required this.isPlaying,
    required this.volume,
    required this.pulseController,
    required this.sleepTimerRemaining,
    required this.onVolumeChanged,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sound.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: sound.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: pulseController,
                builder: (_, child) {
                  final scale = 1.0 + pulseController.value * 0.1;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Text(sound.emoji, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sound.name, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
                    if (sleepTimerRemaining > 0)
                      Text(
                        '${sleepTimerRemaining ~/ 60}:${(sleepTimerRemaining % 60).toString().padLeft(2, '0')} 후 자동 종료',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_rounded, size: 36),
                color: AppTheme.primary,
                onPressed: onStop,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.volume_down, size: 18, color: AppTheme.textSecondary),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: onVolumeChanged,
                  activeColor: sound.color,
                  inactiveColor: sound.color.withOpacity(0.2),
                ),
              ),
              Icon(Icons.volume_up, size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
