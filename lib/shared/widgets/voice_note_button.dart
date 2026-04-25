import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../utils/ui_helpers.dart';

/// Three-state voice recorder: idle → recording → recorded.
///
/// In **idle** state, shows a mic icon suitable for [suffixIcon].
/// In **recording** state, shows a red pulse, elapsed timer, and stop button.
/// In **recorded** state, shows play/pause, progress, duration, and delete.
class VoiceNoteRecorder extends StatefulWidget {
  /// Called when recording completes (file path) or is deleted (null).
  final ValueChanged<String?>? onRecordingChanged;

  /// Icon color when idle.
  final Color? idleColor;

  /// Color accent when recording.
  final Color? recordingColor;

  /// Size of the mic icon. Defaults to 24.
  final double iconSize;

  /// Optional recorder instance for testing.
  @visibleForTesting
  final AudioRecorder? recorder;

  const VoiceNoteRecorder({
    super.key,
    this.onRecordingChanged,
    this.idleColor,
    this.recordingColor,
    this.iconSize = 24,
    this.recorder,
  });

  @override
  State<VoiceNoteRecorder> createState() => VoiceNoteRecorderState();
}

@visibleForTesting
class VoiceNoteRecorderState extends State<VoiceNoteRecorder>
    with SingleTickerProviderStateMixin {
  static const _maxDuration = Duration(minutes: 5);

  AudioRecorder? _recorder;
  AudioPlayer? _player;

  _VoiceState _state = _VoiceState.idle;
  String? _recordedFilePath;

  // Recording timer
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  // Playback
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  // Pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    _recorder?.dispose();
    _pulseController.dispose();
    // Clean up temp file if not saved
    if (_recordedFilePath != null) {
      try {
        File(_recordedFilePath!).deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  // ── Recording ────────────────────────────────────────

  Future<void> _startRecording() async {
    _recorder ??= widget.recorder ?? AudioRecorder();

    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        UIHelpers.showSnackBar(
          context,
          'يرجى السماح بالوصول للميكروفون',
          isError: true,
        );
      }
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= _maxDuration) _stopRecording();
    });

    setState(() => _state = _VoiceState.recording);
    _pulseController.repeat(reverse: true);
    HapticFeedback.lightImpact();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final path = await _recorder?.stop();
    if (path == null || !mounted) return;

    _recordedFilePath = path;

    // Load into player to get duration
    _player ??= AudioPlayer();
    final duration = await _player!.setFilePath(path);
    _playDuration = duration ?? _elapsed;
    _playPosition = Duration.zero;

    _positionSub = _player!.positionStream.listen((pos) {
      if (mounted) setState(() => _playPosition = pos);
    });
    _stateSub = _player!.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _player!.seek(Duration.zero);
        _player!.pause();
        setState(() => _isPlaying = false);
      }
      setState(() => _isPlaying = state.playing);
    });

    setState(() => _state = _VoiceState.recorded);
    widget.onRecordingChanged?.call(path);
    HapticFeedback.lightImpact();
  }

  // ── Playback ─────────────────────────────────────────

  Future<void> _togglePlayback() async {
    if (_player == null) return;
    if (_isPlaying) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  // ── Delete ───────────────────────────────────────────

  Future<void> _deleteRecording() async {
    _positionSub?.cancel();
    _stateSub?.cancel();
    await _player?.stop();

    if (_recordedFilePath != null) {
      try {
        await File(_recordedFilePath!).delete();
      } catch (_) {}
    }

    _recordedFilePath = null;
    _playPosition = Duration.zero;
    _playDuration = Duration.zero;
    _isPlaying = false;

    setState(() => _state = _VoiceState.idle);
    widget.onRecordingChanged?.call(null);
  }

  // ── Helpers ──────────────────────────────────────────

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _VoiceState.idle:
        return _buildIdle();
      case _VoiceState.recording:
        return _buildRecording();
      case _VoiceState.recorded:
        return _buildRecorded();
    }
  }

  Widget _buildIdle() {
    final color =
        widget.idleColor ?? Theme.of(context).iconTheme.color ?? Colors.grey;
    return Semantics(
      label: 'تسجيل صوتي',
      button: true,
      child: GestureDetector(
        onTap: _startRecording,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(Icons.mic_none_rounded, color: color, size: widget.iconSize),
        ),
      ),
    );
  }

  Widget _buildRecording() {
    final color = widget.recordingColor ?? Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing red dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Container(
              width: 12 * _pulseAnimation.value,
              height: 12 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timer
          Text(
            _formatDuration(_elapsed),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          // Stop button
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecorded() {
    final accentColor = Theme.of(context).colorScheme.primary;
    final progress = _playDuration.inMilliseconds > 0
        ? (_playPosition.inMilliseconds / _playDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause
          GestureDetector(
            onTap: _togglePlayback,
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 6),
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: accentColor.withValues(alpha: 0.2),
                color: accentColor,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Duration
          Text(
            _formatDuration(_isPlaying ? _playPosition : _playDuration),
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          // Delete
          GestureDetector(
            onTap: _deleteRecording,
            child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
          ),
        ],
      ),
    );
  }
}

enum _VoiceState { idle, recording, recorded }
