import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A self-contained voice-to-text button that uses speech recognition
/// to transcribe Arabic speech into text.
///
/// Shows a mic icon that pulses red while actively listening.
/// Hides itself when speech recognition is unavailable on the device.
///
/// Usage:
/// ```dart
/// VoiceNoteButton(
///   controller: notesController,
///   onTextReceived: (text) => debugPrint('Transcribed: $text'),
/// )
/// ```
class VoiceNoteButton extends StatefulWidget {
  /// Called when speech is recognized with the transcribed text.
  /// If null, text is only appended to the [controller].
  final ValueChanged<String>? onTextReceived;

  /// Optional controller to append transcribed text to directly.
  /// If provided, recognized text is appended to the controller's
  /// current text (separated by a newline if not empty).
  final TextEditingController? controller;

  /// Icon color when idle. Defaults to the theme's icon color.
  final Color? idleColor;

  /// Icon color when actively listening. Defaults to red.
  final Color? listeningColor;

  /// Size of the icon. Defaults to 24.
  final double iconSize;

  /// Optional speech-to-text instance for testing.
  @visibleForTesting
  final SpeechToText? speechToText;

  const VoiceNoteButton({
    super.key,
    this.onTextReceived,
    this.controller,
    this.idleColor,
    this.listeningColor,
    this.iconSize = 24,
    this.speechToText,
  });

  @override
  State<VoiceNoteButton> createState() => VoiceNoteButtonState();
}

@visibleForTesting
class VoiceNoteButtonState extends State<VoiceNoteButton>
    with SingleTickerProviderStateMixin {
  late final SpeechToText _speech = widget.speechToText ?? SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  bool _hasCheckedAvailability = false;
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
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          _stopListening();
        },
        onStatus: (status) {
          // When the speech recognizer stops on its own (e.g., silence timeout),
          // update our state to match.
          if (status == 'notListening' && _isListening) {
            _stopListening();
          }
        },
      );
    } catch (e) {
      debugPrint('Speech recognition init failed: $e');
      _isAvailable = false;
    }

    _hasCheckedAvailability = true;
    if (mounted) setState(() {});
  }

  Future<void> _startListening() async {
    if (!_isAvailable) return;

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final text = result.recognizedWords.trim();
            if (text.isNotEmpty) {
              widget.onTextReceived?.call(text);
              _appendToController(text);
            }
            _stopListening();
          }
        },
        localeId: 'ar_SA', // Saudi Arabic
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: false,
        ),
      );

      if (mounted) {
        setState(() => _isListening = true);
        _pulseController.repeat(reverse: true);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      _stopListening();
    }
  }

  void _stopListening() {
    if (!_isListening) return; // guard against re-entrant calls
    _isListening = false;
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();
    if (mounted) {
      setState(() {});
      HapticFeedback.lightImpact();
    }
  }

  void _appendToController(String text) {
    final controller = widget.controller;
    if (controller == null) return;

    final existing = controller.text;
    if (existing.isEmpty) {
      controller.text = text;
    } else {
      controller.text = '$existing\n$text';
    }
    // Move cursor to end
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  }

  @override
  void dispose() {
    try {
      _speech.stop();
    } catch (_) {
      // Platform channel may already be torn down
    }
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide entirely if speech recognition is not available
    // (or while still checking availability)
    if (!_hasCheckedAvailability || !_isAvailable) {
      return const SizedBox.shrink();
    }

    final idleColor =
        widget.idleColor ?? Theme.of(context).iconTheme.color ?? Colors.grey;
    final listeningColor = widget.listeningColor ?? Colors.red;

    return Semantics(
      label: _isListening ? 'إيقاف التسجيل الصوتي' : 'تسجيل صوتي',
      button: true,
      child: GestureDetector(
        onTap: _isListening ? _stopListening : _startListening,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing red circle behind mic when listening
                  if (_isListening)
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: widget.iconSize + 12,
                        height: widget.iconSize + 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: listeningColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  Icon(
                    _isListening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    color: _isListening ? listeningColor : idleColor,
                    size: widget.iconSize,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
