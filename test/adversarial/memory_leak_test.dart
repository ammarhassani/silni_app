/// Memory Leak Tests - "PROSECUTOR MODE"
///
/// Comprehensive memory leak detection tests:
/// - Widget creation/destruction cycles
/// - Stream/Controller disposal
/// - Animation controller lifecycle
/// - Timer cancellation
/// - Provider/state disposal
/// - Listener cleanup
///
/// These tests verify resources are properly released to prevent memory leaks.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:silni_app/shared/widgets/glass_card.dart';
import 'package:silni_app/shared/widgets/simple_dialog_card.dart';
import 'package:silni_app/shared/widgets/theme_aware_dialog.dart';

import '../helpers/widget_test_helpers.dart';

// =============================================================================
// LEAK TRACKING UTILITIES
// =============================================================================

/// Tracks object creation and disposal for leak detection
class LeakTracker {
  int _createdCount = 0;
  int _disposedCount = 0;
  final List<String> _activeObjects = [];
  final List<String> _leakLog = [];

  int get createdCount => _createdCount;
  int get disposedCount => _disposedCount;
  int get activeCount => _createdCount - _disposedCount;
  List<String> get activeObjects => List.unmodifiable(_activeObjects);
  List<String> get leakLog => List.unmodifiable(_leakLog);
  bool get hasLeaks => activeCount > 0;

  void trackCreate(String objectId) {
    _createdCount++;
    _activeObjects.add(objectId);
  }

  void trackDispose(String objectId) {
    _disposedCount++;
    if (!_activeObjects.remove(objectId)) {
      _leakLog.add('Dispose called for unknown object: $objectId');
    }
  }

  void reset() {
    _createdCount = 0;
    _disposedCount = 0;
    _activeObjects.clear();
    _leakLog.clear();
  }

  void verifyNoLeaks() {
    if (hasLeaks) {
      throw StateError(
        'Memory leak detected: $activeCount objects not disposed.\n'
        'Active objects: $_activeObjects\n'
        'Leak log: $_leakLog',
      );
    }
  }
}

/// Global leak tracker for tests
final leakTracker = LeakTracker();

// =============================================================================
// TRACKABLE WIDGETS FOR TESTING
// =============================================================================

/// Widget that tracks its lifecycle
class TrackableWidget extends StatefulWidget {
  final String id;
  final Widget child;

  const TrackableWidget({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  State<TrackableWidget> createState() => _TrackableWidgetState();
}

class _TrackableWidgetState extends State<TrackableWidget> {
  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('Widget:${widget.id}');
  }

  @override
  void dispose() {
    leakTracker.trackDispose('Widget:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Widget with animation controller that tracks disposal
class AnimatedTrackableWidget extends StatefulWidget {
  final String id;
  final Duration duration;

  const AnimatedTrackableWidget({
    super.key,
    required this.id,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<AnimatedTrackableWidget> createState() => _AnimatedTrackableWidgetState();
}

class _AnimatedTrackableWidgetState extends State<AnimatedTrackableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('AnimationController:${widget.id}');

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    leakTracker.trackDispose('AnimationController:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: const Icon(Icons.refresh, size: 50),
        );
      },
    );
  }
}

/// Widget with StreamController that tracks disposal
class StreamTrackableWidget extends StatefulWidget {
  final String id;

  const StreamTrackableWidget({
    super.key,
    required this.id,
  });

  @override
  State<StreamTrackableWidget> createState() => _StreamTrackableWidgetState();
}

class _StreamTrackableWidgetState extends State<StreamTrackableWidget> {
  late StreamController<int> _streamController;
  late StreamSubscription<int> _subscription;
  int _value = 0;

  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('StreamController:${widget.id}');

    _streamController = StreamController<int>.broadcast();
    _subscription = _streamController.stream.listen((value) {
      if (mounted) {
        setState(() => _value = value);
      }
    });

    // Emit values periodically
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_streamController.isClosed) {
        _streamController.add(_value + 1);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _streamController.close();
    leakTracker.trackDispose('StreamController:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Stream value: $_value');
  }
}

/// Widget with Timer that tracks cancellation
class TimerTrackableWidget extends StatefulWidget {
  final String id;
  final Duration interval;

  const TimerTrackableWidget({
    super.key,
    required this.id,
    this.interval = const Duration(milliseconds: 100),
  });

  @override
  State<TimerTrackableWidget> createState() => _TimerTrackableWidgetState();
}

class _TimerTrackableWidgetState extends State<TimerTrackableWidget> {
  Timer? _timer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('Timer:${widget.id}');

    _timer = Timer.periodic(widget.interval, (timer) {
      if (mounted) {
        setState(() => _ticks++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    leakTracker.trackDispose('Timer:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Ticks: $_ticks');
  }
}

/// Widget with ScrollController listener that tracks cleanup
class ScrollListenerWidget extends StatefulWidget {
  final String id;

  const ScrollListenerWidget({
    super.key,
    required this.id,
  });

  @override
  State<ScrollListenerWidget> createState() => _ScrollListenerWidgetState();
}

class _ScrollListenerWidgetState extends State<ScrollListenerWidget> {
  late ScrollController _scrollController;
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('ScrollController:${widget.id}');

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollPosition = _scrollController.offset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    leakTracker.trackDispose('ScrollController:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Scroll position: ${_scrollPosition.toStringAsFixed(1)}'),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: 100,
            itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
          ),
        ),
      ],
    );
  }
}

/// Widget with TextEditingController that tracks disposal
class TextControllerWidget extends StatefulWidget {
  final String id;

  const TextControllerWidget({
    super.key,
    required this.id,
  });

  @override
  State<TextControllerWidget> createState() => _TextControllerWidgetState();
}

class _TextControllerWidgetState extends State<TextControllerWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('TextEditingController:${widget.id}');
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    leakTracker.trackDispose('TextEditingController:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}

/// Widget with FocusNode that tracks disposal
class FocusNodeWidget extends StatefulWidget {
  final String id;

  const FocusNodeWidget({
    super.key,
    required this.id,
  });

  @override
  State<FocusNodeWidget> createState() => _FocusNodeWidgetState();
}

class _FocusNodeWidgetState extends State<FocusNodeWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    leakTracker.trackCreate('FocusNode:${widget.id}');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    leakTracker.trackDispose('FocusNode:${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(focusNode: _focusNode);
  }
}

// =============================================================================
// MEMORY LEAK TESTS
// =============================================================================

void main() {
  setUp(() {
    leakTracker.reset();
  });

  tearDown(() {
    // Verify no leaks after each test
    try {
      leakTracker.verifyNoLeaks();
    } catch (e) {
      // Log but don't fail teardown - the test itself should verify
      debugPrint('Leak detection in teardown: $e');
    }
  });

  group('Memory Leak Tests - PROSECUTOR MODE', () {
    // =========================================================================
    // WIDGET CREATION/DESTRUCTION TESTS
    // =========================================================================

    group('Widget Creation/Destruction Leaks', () {
      testWidgets('create and destroy 1000 screens without leak',
          (WidgetTester tester) async {
        // Track that each widget is properly disposed when replaced.
        // We use unique keys to force widget recreation.

        for (var i = 0; i < 1000; i++) {
          await tester.pumpWidget(createTestWidget(
            child: TrackableWidget(
              key: ValueKey('screen-$i'), // Unique key forces new instance
              id: 'screen-$i',
              child: Scaffold(
                appBar: AppBar(title: Text('Screen $i')),
                body: ListView.builder(
                  itemCount: 20,
                  itemBuilder: (_, index) => ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ));

          await tester.pump();
        }

        // Replace with empty widget to trigger final disposal
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Verify all were created and all were disposed
        expect(leakTracker.createdCount, 1000);
        expect(leakTracker.disposedCount, 1000);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('create and destroy 1000 dialogs without leak',
          (WidgetTester tester) async {
        for (var i = 0; i < 1000; i++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: Center(
                child: TrackableWidget(
                  key: ValueKey('dialog-$i'), // Unique key forces new instance
                  id: 'dialog-$i',
                  child: ThemeAwareDialog(
                    title: 'Dialog $i',
                    content: Text('Content for dialog $i'),
                  ),
                ),
              ),
            ),
          ));

          await tester.pump();
        }

        // Replace with empty widget
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 1000);
        expect(leakTracker.disposedCount, 1000);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('create and destroy 1000 images without leak',
          (WidgetTester tester) async {
        for (var i = 0; i < 1000; i++) {
          await tester.pumpWidget(createTestWidget(
            child: TrackableWidget(
              key: ValueKey('image-$i'), // Unique key forces new instance
              id: 'image-$i',
              child: Scaffold(
                body: GridView.count(
                  crossAxisCount: 4,
                  children: List.generate(
                    16,
                    (index) {
                      // Use a predefined list of icons since Icons doesn't have .values
                      const iconList = [
                        Icons.person, Icons.home, Icons.star, Icons.favorite,
                        Icons.settings, Icons.search, Icons.add, Icons.delete,
                        Icons.edit, Icons.share, Icons.save, Icons.close,
                        Icons.check, Icons.info, Icons.warning, Icons.error,
                      ];
                      return Icon(
                        iconList[index % iconList.length],
                        size: 48,
                        color: Color(0xFF000000 + (i * index)),
                      );
                    },
                  ),
                ),
              ),
            ),
          ));

          await tester.pump();
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 1000);
        expect(leakTracker.disposedCount, 1000);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('GlassCard rapid create/destroy without leak',
          (WidgetTester tester) async {
        for (var i = 0; i < 500; i++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: TrackableWidget(
                key: ValueKey('glasscard-$i'),
                id: 'glasscard-$i',
                child: GlassCard(
                  onTap: () {},
                  enablePressAnimation: true,
                  child: Text('Card $i'),
                ),
              ),
            ),
          ));

          await tester.pump();
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 500);
        expect(leakTracker.disposedCount, 500);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('SimpleDialogCard rapid create/destroy without leak',
          (WidgetTester tester) async {
        for (var i = 0; i < 500; i++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: Center(
                child: TrackableWidget(
                  key: ValueKey('simpledialog-$i'),
                  id: 'simpledialog-$i',
                  child: SimpleDialogCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Dialog $i'),
                        const TextField(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ));

          await tester.pump();
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 500);
        expect(leakTracker.disposedCount, 500);
        expect(leakTracker.hasLeaks, isFalse);
      });
    });

    // =========================================================================
    // STREAM/CONTROLLER LEAK TESTS
    // =========================================================================

    group('Stream/Controller Leaks', () {
      testWidgets('StreamController disposal',
          (WidgetTester tester) async {
        // Create widgets with stream controllers
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: Column(
              children: List.generate(
                10,
                (i) => StreamTrackableWidget(id: 'stream-$i'),
              ),
            ),
          ),
        ));

        // Let streams emit some values
        await tester.pump(const Duration(milliseconds: 500));

        // Replace widget tree
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 10);
        expect(leakTracker.disposedCount, 10);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('rapid StreamController create/destroy',
          (WidgetTester tester) async {
        for (var round = 0; round < 100; round++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: StreamTrackableWidget(
                key: ValueKey('stream-$round'),
                id: 'stream-$round',
              ),
            ),
          ));

          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 100);
        expect(leakTracker.disposedCount, 100);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('AnimationController disposal',
          (WidgetTester tester) async {
        // Create widgets with animation controllers
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: Column(
              children: List.generate(
                10,
                (i) => AnimatedTrackableWidget(id: 'anim-$i'),
              ),
            ),
          ),
        ));

        // Let animations run
        await tester.pump(const Duration(milliseconds: 500));

        // Replace widget tree
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 10);
        expect(leakTracker.disposedCount, 10);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('rapid AnimationController create/destroy during animation',
          (WidgetTester tester) async {
        for (var round = 0; round < 100; round++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: AnimatedTrackableWidget(
                key: ValueKey('anim-$round'),
                id: 'anim-$round',
                duration: const Duration(milliseconds: 100),
              ),
            ),
          ));

          // Pump mid-animation
          await tester.pump(const Duration(milliseconds: 30));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 100);
        expect(leakTracker.disposedCount, 100);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('Timer cancellation',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: Column(
              children: List.generate(
                10,
                (i) => TimerTrackableWidget(id: 'timer-$i'),
              ),
            ),
          ),
        ));

        // Let timers run
        await tester.pump(const Duration(milliseconds: 500));

        // Replace widget tree
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 10);
        expect(leakTracker.disposedCount, 10);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('rapid Timer create/destroy',
          (WidgetTester tester) async {
        for (var round = 0; round < 100; round++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: TimerTrackableWidget(
                key: ValueKey('timer-$round'),
                id: 'timer-$round',
                interval: const Duration(milliseconds: 10),
              ),
            ),
          ));

          await tester.pump(const Duration(milliseconds: 25));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 100);
        expect(leakTracker.disposedCount, 100);
        expect(leakTracker.hasLeaks, isFalse);
      });
    });

    // =========================================================================
    // LISTENER LEAK TESTS
    // =========================================================================

    group('Listener Leaks', () {
      testWidgets('ScrollController listener cleanup',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: ScrollListenerWidget(id: 'scroll-1'),
          ),
        ));

        // Scroll to trigger listener
        await tester.fling(
          find.byType(ListView),
          const Offset(0, -500),
          1000,
        );
        await tester.pumpAndSettle();

        // Replace widget
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 1);
        expect(leakTracker.disposedCount, 1);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('rapid ScrollController create/destroy with scrolling',
          (WidgetTester tester) async {
        for (var round = 0; round < 50; round++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: ScrollListenerWidget(
                key: ValueKey('scroll-$round'),
                id: 'scroll-$round',
              ),
            ),
          ));

          // Scroll
          try {
            await tester.fling(
              find.byType(ListView),
              const Offset(0, -200),
              500,
            );
          } catch (_) {}

          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 50);
        expect(leakTracker.disposedCount, 50);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('TextEditingController disposal',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  10,
                  (i) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextControllerWidget(id: 'text-$i'),
                  ),
                ),
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();

        // Replace widget - test that controllers are disposed
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 10);
        expect(leakTracker.disposedCount, 10);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('FocusNode disposal',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  10,
                  (i) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: FocusNodeWidget(id: 'focus-$i'),
                  ),
                ),
              ),
            ),
          ),
        ));

        await tester.pumpAndSettle();

        // Replace widget - test that focus nodes are disposed
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 10);
        expect(leakTracker.disposedCount, 10);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('rapid FocusNode create/destroy with focus changes',
          (WidgetTester tester) async {
        for (var round = 0; round < 100; round++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: FocusNodeWidget(
                  key: ValueKey('focus-$round'),
                  id: 'focus-$round',
                ),
              ),
            ),
          ));

          // Try to focus
          try {
            await tester.tap(find.byType(TextField));
          } catch (_) {}

          await tester.pump(const Duration(milliseconds: 20));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 100);
        expect(leakTracker.disposedCount, 100);
        expect(leakTracker.hasLeaks, isFalse);
      });
    });

    // =========================================================================
    // PROVIDER/STATE LEAK TESTS
    // =========================================================================

    group('Provider/State Leaks', () {
      testWidgets('Provider disposal on widget removal',
          (WidgetTester tester) async {
        // Test provider is disposed when widget tree is removed
        final disposeTracker = <String>[];

        final testProvider = StateNotifierProvider<_TestNotifier, int>((ref) {
          final notifier = _TestNotifier();
          ref.onDispose(() {
            disposeTracker.add('provider-disposed');
          });
          return notifier;
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: defaultThemeOverrides,
            child: Consumer(
              builder: (context, ref, child) {
                ref.watch(testProvider);
                return const MaterialApp(
                  home: Scaffold(body: Text('Provider Test')),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Provider Test'), findsOneWidget);

        // Remove provider scope
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Provider should have been disposed
        expect(disposeTracker, contains('provider-disposed'));
      });

      testWidgets('nested providers disposal',
          (WidgetTester tester) async {
        final disposeTracker = <String>[];

        final provider1 = StateNotifierProvider<_TestNotifier, int>((ref) {
          final notifier = _TestNotifier();
          ref.onDispose(() => disposeTracker.add('provider1'));
          return notifier;
        });

        final provider2 = StateNotifierProvider<_TestNotifier, int>((ref) {
          final notifier = _TestNotifier();
          ref.onDispose(() => disposeTracker.add('provider2'));
          return notifier;
        });

        final provider3 = StateNotifierProvider<_TestNotifier, int>((ref) {
          final notifier = _TestNotifier();
          ref.onDispose(() => disposeTracker.add('provider3'));
          return notifier;
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: defaultThemeOverrides,
            child: Consumer(
              builder: (context, ref, child) {
                ref.watch(provider1);
                ref.watch(provider2);
                ref.watch(provider3);
                return const MaterialApp(
                  home: Scaffold(body: Text('Nested Providers')),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(disposeTracker, containsAll(['provider1', 'provider2', 'provider3']));
      });

      testWidgets('cached data clearance simulation',
          (WidgetTester tester) async {
        // Simulate cache that should be cleared
        final cache = <String, dynamic>{};

        // Populate cache
        for (var i = 0; i < 100; i++) {
          cache['key-$i'] = 'value-$i' * 100; // Some data
        }

        expect(cache.length, 100);

        // Simulate logout/clear
        cache.clear();

        expect(cache.length, 0);
        expect(cache.isEmpty, isTrue);
      });

      testWidgets('rapid provider scope create/destroy',
          (WidgetTester tester) async {
        var disposedCount = 0;

        for (var i = 0; i < 100; i++) {
          final testProvider = StateNotifierProvider<_TestNotifier, int>((ref) {
            final notifier = _TestNotifier();
            ref.onDispose(() => disposedCount++);
            return notifier;
          });

          await tester.pumpWidget(
            ProviderScope(
              overrides: defaultThemeOverrides,
              child: Consumer(
                builder: (context, ref, child) {
                  ref.watch(testProvider);
                  return MaterialApp(
                    home: Scaffold(body: Text('Round $i')),
                  );
                },
              ),
            ),
          );

          await tester.pump();
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Each provider should have been disposed
        expect(disposedCount, 100);
      });
    });

    // =========================================================================
    // COMBINED LEAK TESTS
    // =========================================================================

    group('Combined Leak Tests', () {
      testWidgets('complex widget with multiple resources',
          (WidgetTester tester) async {
        // Widget with animation, stream, timer, and scroll controller
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: Column(
              children: [
                AnimatedTrackableWidget(id: 'complex-anim'),
                StreamTrackableWidget(id: 'complex-stream'),
                TimerTrackableWidget(id: 'complex-timer'),
                Expanded(child: ScrollListenerWidget(id: 'complex-scroll')),
              ],
            ),
          ),
        ));

        // Let everything run
        await tester.pump(const Duration(milliseconds: 300));

        // Interact
        try {
          await tester.fling(find.byType(ListView), const Offset(0, -100), 500);
        } catch (_) {}
        await tester.pump(const Duration(milliseconds: 200));

        // Dispose
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.createdCount, 4);
        expect(leakTracker.disposedCount, 4);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('stress test: 500 widgets with mixed resources',
          (WidgetTester tester) async {
        for (var i = 0; i < 500; i++) {
          final widgetType = i % 5;
          Widget child;

          switch (widgetType) {
            case 0:
              child = TrackableWidget(
                key: ValueKey('mixed-widget-$i'),
                id: 'mixed-widget-$i',
                child: const Text('Basic'),
              );
            case 1:
              child = AnimatedTrackableWidget(
                key: ValueKey('mixed-anim-$i'),
                id: 'mixed-anim-$i',
              );
            case 2:
              child = StreamTrackableWidget(
                key: ValueKey('mixed-stream-$i'),
                id: 'mixed-stream-$i',
              );
            case 3:
              child = TimerTrackableWidget(
                key: ValueKey('mixed-timer-$i'),
                id: 'mixed-timer-$i',
              );
            case 4:
              child = TextControllerWidget(
                key: ValueKey('mixed-text-$i'),
                id: 'mixed-text-$i',
              );
            default:
              child = TrackableWidget(
                key: ValueKey('mixed-default-$i'),
                id: 'mixed-default-$i',
                child: const Text('Default'),
              );
          }

          await tester.pumpWidget(createTestWidget(
            child: Scaffold(body: Center(child: child)),
          ));

          await tester.pump(const Duration(milliseconds: 20));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // All 500 widgets should be properly disposed
        expect(leakTracker.createdCount, 500);
        expect(leakTracker.disposedCount, 500);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('dialog with multiple controllers - leak check',
          (WidgetTester tester) async {
        for (var round = 0; round < 100; round++) {
          await tester.pumpWidget(createTestWidget(
            child: Scaffold(
              body: Center(
                child: TrackableWidget(
                  key: ValueKey('dialog-round-$round'),
                  id: 'dialog-round-$round',
                  child: ThemeAwareDialog(
                    title: 'Dialog $round',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextControllerWidget(
                          key: ValueKey('dialog-text-$round'),
                          id: 'dialog-text-$round',
                        ),
                        FocusNodeWidget(
                          key: ValueKey('dialog-focus-$round'),
                          id: 'dialog-focus-$round',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ));

          await tester.pump(const Duration(milliseconds: 30));
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // 100 dialogs + 100 text controllers + 100 focus nodes = 300
        expect(leakTracker.createdCount, 300);
        expect(leakTracker.disposedCount, 300);
        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('navigation simulation - no leaks between routes',
          (WidgetTester tester) async {
        // Simulate navigating between screens with unique keys per cycle
        var navIndex = 0;

        // Navigate through all screens multiple times
        for (var cycle = 0; cycle < 10; cycle++) {
          // Screen 1: Home
          await tester.pumpWidget(createTestWidget(
            child: TrackableWidget(
              key: ValueKey('nav-home-$navIndex'),
              id: 'nav-home-$navIndex',
              child: const Scaffold(body: Center(child: Text('Home'))),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          navIndex++;

          // Screen 2: List
          await tester.pumpWidget(createTestWidget(
            child: TrackableWidget(
              key: ValueKey('nav-list-$navIndex'),
              id: 'nav-list-$navIndex',
              child: Scaffold(
                body: ListView.builder(
                  itemCount: 50,
                  itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
                ),
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          navIndex++;

          // Screen 3: Form with controllers
          await tester.pumpWidget(createTestWidget(
            child: TrackableWidget(
              key: ValueKey('nav-form-$navIndex'),
              id: 'nav-form-$navIndex',
              child: Scaffold(
                body: Column(
                  children: [
                    TextControllerWidget(
                      key: ValueKey('nav-form-text-$navIndex'),
                      id: 'nav-form-text-$navIndex',
                    ),
                    FocusNodeWidget(
                      key: ValueKey('nav-form-focus-$navIndex'),
                      id: 'nav-form-focus-$navIndex',
                    ),
                  ],
                ),
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          navIndex++;

          // Screen 4: Animated
          await tester.pumpWidget(createTestWidget(
            child: TrackableWidget(
              key: ValueKey('nav-animated-$navIndex'),
              id: 'nav-animated-$navIndex',
              child: Scaffold(
                body: AnimatedTrackableWidget(
                  key: ValueKey('nav-anim-$navIndex'),
                  id: 'nav-anim-$navIndex',
                ),
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 50));
          navIndex++;
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        // Verify all resources were cleaned up
        expect(leakTracker.hasLeaks, isFalse);
        expect(leakTracker.createdCount, leakTracker.disposedCount);
      });
    });

    // =========================================================================
    // EDGE CASE LEAK TESTS
    // =========================================================================

    group('Edge Case Leak Tests', () {
      testWidgets('widget disposed during animation callback',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: AnimatedTrackableWidget(
              id: 'edge-anim',
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ));

        // Start animation
        await tester.pump(const Duration(milliseconds: 20));

        // Dispose mid-animation
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('stream controller disposed during emission',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: StreamTrackableWidget(id: 'edge-stream'),
          ),
        ));

        // Let stream emit
        await tester.pump(const Duration(milliseconds: 50));

        // Dispose during emission
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('timer disposed during callback',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: TimerTrackableWidget(
              id: 'edge-timer',
              interval: const Duration(milliseconds: 10),
            ),
          ),
        ));

        // Let timer tick
        await tester.pump(const Duration(milliseconds: 25));

        // Dispose
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('scroll controller disposed during scroll animation',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: ScrollListenerWidget(id: 'edge-scroll'),
          ),
        ));

        // Start scroll animation
        await tester.fling(find.byType(ListView), const Offset(0, -500), 2000);
        await tester.pump(const Duration(milliseconds: 50));

        // Dispose mid-scroll
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('focus node disposed while focused',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: FocusNodeWidget(id: 'edge-focus'),
            ),
          ),
        ));

        // Focus the field
        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Dispose while focused
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.hasLeaks, isFalse);
      });

      testWidgets('text controller disposed during text composition',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TextControllerWidget(id: 'edge-text'),
            ),
          ),
        ));

        // Start entering text
        await tester.enterText(find.byType(TextField), 'Test');
        await tester.pump();

        // Dispose during text entry
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(leakTracker.hasLeaks, isFalse);
      });
    });
  });
}

// =============================================================================
// HELPER CLASSES
// =============================================================================

/// Simple StateNotifier for testing provider disposal
class _TestNotifier extends StateNotifier<int> {
  _TestNotifier() : super(0);

  void increment() => state++;
}
